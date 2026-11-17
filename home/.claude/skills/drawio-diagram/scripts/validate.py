#!/usr/bin/env python3
"""draw.io ファイルの構造を検査する。標準ライブラリのみ。

使い方: python3 validate.py diagram.drawio
終了コード: 0 = 問題なし（警告のみ含む）、1 = エラーあり
"""
import re
import sys
import xml.etree.ElementTree as ET

GEOMETRY_ATTRS = {"x", "y", "width", "height", "relative", "as"}
# 図形の下に出るラベル 1 行あたりの高さ（fontSize=12 の目安）
LABEL_LINE_HEIGHT = 14


def find_models(root):
    if root.tag == "mxGraphModel":
        return [("(single)", root)]
    if root.tag != "mxfile":
        raise ValueError(f"ルート要素が mxfile / mxGraphModel ではない: <{root.tag}>")
    diagrams = root.findall("diagram")
    if not diagrams:
        raise ValueError("<diagram> が1つも無い")
    models = []
    for diagram in diagrams:
        name = diagram.get("name", "(no name)")
        model = diagram.find("mxGraphModel")
        if model is None:
            if (diagram.text or "").strip():
                raise ValueError(f"ページ「{name}」が圧縮されている。非圧縮の mxGraphModel で書く")
            raise ValueError(f"ページ「{name}」が空")
        models.append((name, model))
    return models


def parse_style(style):
    pairs = (kv.split("=", 1) for kv in (style or "").split(";") if "=" in kv)
    return {k: v for k, v in pairs}


def num(value, default=0.0):
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def label_lines(label):
    if not label:
        return 0
    return label.count("\n") + len(re.findall(r"<br\s*/?>", label)) + 1


class Cell:
    def __init__(self, cell_id, wrapper):
        self.id = cell_id
        # object / UserObject で包んだセルは、ラベルを label 属性に持つ
        self.cell = wrapper if wrapper.tag == "mxCell" else wrapper.find("mxCell")
        self.label = wrapper.get("value" if wrapper is self.cell else "label", "")
        c = self.cell if self.cell is not None else wrapper
        self.parent = c.get("parent")
        self.vertex = c.get("vertex")
        self.edge = c.get("edge")
        self.style = parse_style(c.get("style"))
        self.geo = c.find("mxGeometry")


def check_model(model):
    errors, warnings = [], []
    root = model.find("root")
    if root is None:
        return ["<root> が無い"], warnings

    by_id, cells = {}, []
    for wrapper in root:
        cell_id = wrapper.get("id")
        if cell_id is None:
            errors.append(f"id の無い要素: <{wrapper.tag}>")
            continue
        if cell_id in by_id:
            errors.append(f"id の重複: {cell_id}")
        cell = Cell(cell_id, wrapper)
        if cell.cell is None:
            errors.append(f"{cell_id}: mxCell を持たない")
            continue
        by_id[cell_id] = cell
        cells.append(cell)

    # ルート（parent なし）はちょうど1つ、その直下がレイヤー。id は "0"/"1" とは限らない
    roots = [c.id for c in cells if c.parent is None]
    if len(roots) != 1:
        errors.append(f"parent の無いセル（ルート）が {len(roots)} 個（1 個であるべき）: {roots}")
    root_id = roots[0] if roots else None
    layers = set()
    for c in cells:
        if c.parent is None or c.parent != root_id:
            continue
        if c.vertex == "1" or c.edge == "1":
            errors.append(f"{c.id}: 図形や線がルート直下にある。レイヤー（通常 id=\"1\"）を parent にする")
        else:
            layers.add(c.id)
    if not layers:
        errors.append("レイヤー（ルート直下のセル）が無い")

    for c in cells:
        if c.id == root_id or c.id in layers:
            continue
        if c.parent not in by_id:
            errors.append(f"{c.id}: parent={c.parent} が存在しない")
            continue
        if has_cycle(c, by_id):
            errors.append(f"{c.id}: parent をたどると循環する")
            continue
        if c.vertex != "1" and c.edge != "1":
            errors.append(f'{c.id}: vertex="1" も edge="1" も無い（vertex={c.vertex}, edge={c.edge}）')
            continue
        if "\\n" in c.label:
            warnings.append(f"{c.id}: ラベルに文字列 \\n がある。改行は &#xa; で書く")
        if c.geo is None:
            errors.append(f"{c.id}: mxGeometry が無い（描画されない）")
            continue
        if c.geo.get("as") != "geometry":
            errors.append(f'{c.id}: mxGeometry に as="geometry" が無い（描画されない）')
        if c.edge == "1":
            check_edge(c, by_id, layers, errors, warnings)
        else:
            check_vertex(c, by_id, errors, warnings)
    return errors, warnings


def has_cycle(cell, by_id):
    seen = set()
    while cell is not None and cell.parent is not None:
        if cell.id in seen:
            return True
        seen.add(cell.id)
        cell = by_id.get(cell.parent)
    return False


def check_edge(c, by_id, layers, errors, warnings):
    if c.parent not in layers:
        warnings.append(f"{c.id}: 線の parent={c.parent} がレイヤーではない")
    for end, point in (("source", "sourcePoint"), ("target", "targetPoint")):
        ref = c.cell.get(end)
        if ref is None:
            if c.geo.find(f"mxPoint[@as='{point}']") is None:
                warnings.append(f"{c.id}: {end} も {point} も無い（端点が決まらない）")
        elif ref not in by_id:
            errors.append(f"{c.id}: {end}={ref} が存在しない")

    # 下の辺から出入りする線は、ラベルの下までずらす
    for side, end in (("exit", "source"), ("entry", "target")):
        s = c.style
        if s.get(f"{side}Y") != "1" or s.get(f"{side}Perimeter") != "0":
            continue
        shape = by_id.get(c.cell.get(end))
        if shape is None or shape.style.get("verticalLabelPosition") != "bottom":
            continue
        need = 10 + LABEL_LINE_HEIGHT * label_lines(shape.label)
        if num(s.get(f"{side}Dy")) < need:
            warnings.append(
                f"{c.id}: {side}Dy={s.get(f'{side}Dy', 0)} では {shape.id} のラベル"
                f"（{label_lines(shape.label)} 行）を貫く。{need} 以上にする"
            )


def check_vertex(c, by_id, errors, warnings):
    unknown = set(c.geo.attrib) - GEOMETRY_ATTRS
    if unknown:
        errors.append(f"{c.id}: mxGeometry に未知の属性 {sorted(unknown)}（draw.io は無視する）")
    # 線に付くラベル（relative="1"）は寸法を持たない
    if c.geo.get("relative") == "1":
        return
    w, h = num(c.geo.get("width")), num(c.geo.get("height"))
    if w <= 0 or h <= 0:
        errors.append(f"{c.id}: width / height が無いか 0（図形が描画されない）")
        return

    parent = by_id.get(c.parent)
    if parent is None or parent.vertex != "1" or parent.geo is None:
        return
    x, y = num(c.geo.get("x")), num(c.geo.get("y"))
    if c.style.get("verticalLabelPosition") == "bottom":
        h += LABEL_LINE_HEIGHT * label_lines(c.label) + 4
    pw, ph = num(parent.geo.get("width")), num(parent.geo.get("height"))
    if x < 0 or y < 0 or x + w > pw or y + h > ph:
        warnings.append(
            f"{c.id}: 親 {parent.id}（{pw:g}x{ph:g}）からはみ出している"
            f"（x={x:g}, y={y:g}, ラベル込み {w:g}x{h:g}）"
        )


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    if len(sys.argv) != 2:
        print("usage: validate.py <file.drawio>", file=sys.stderr)
        return 2
    try:
        models = find_models(ET.parse(sys.argv[1]).getroot())
    except (ET.ParseError, ValueError) as e:
        print(f"ERROR: {e}")
        return 1

    has_error = False
    for name, model in models:
        errors, warnings = check_model(model)
        for e in errors:
            print(f"ERROR [{name}] {e}")
        for w in warnings:
            print(f"WARN  [{name}] {w}")
        has_error = has_error or bool(errors)
    if not has_error:
        print(f"OK: {len(models)} page(s)")
    return 1 if has_error else 0


if __name__ == "__main__":
    sys.exit(main())
