"""Print the first rows of every sheet in an .xlsx file, using only the standard library.

Usage: python dump_xlsx.py file.xlsx [max_rows]
"""
import sys
import re
import zipfile
import xml.etree.ElementTree as ET

NS = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"


def natural(name):
    """Return the number in a sheet file name, for sorting sheet10 after sheet2."""
    return int(re.findall(r"\d+", name)[-1])


def dump(path, max_rows=40):
    """Print the sheets of an .xlsx file as 'cell=value' lines."""
    z = zipfile.ZipFile(path)
    strings = []  # shared strings: text cells store an index into this list
    if "xl/sharedStrings.xml" in z.namelist():
        root = ET.fromstring(z.read("xl/sharedStrings.xml"))
        for si in root.findall(NS + "si"):
            strings.append("".join(t.text or "" for t in si.iter(NS + "t")))
    wb = ET.fromstring(z.read("xl/workbook.xml"))
    names = [s.get("name") for s in wb.find(NS + "sheets")]
    # Sheet files are assumed to be stored in workbook order.
    files = sorted((n for n in z.namelist()
                    if re.match(r"xl/worksheets/sheet\d+\.xml$", n)), key=natural)
    for name, f in zip(names, files):
        print(f"\n===== sheet: {name} ({f}) =====")
        sheet = ET.fromstring(z.read(f))
        shown = 0
        for row in sheet.iter(NS + "row"):
            cells = []
            for c in row.findall(NS + "c"):
                v = c.find(NS + "v")
                if c.get("t") == "inlineStr":
                    val = "".join(t.text or "" for t in c.iter(NS + "t"))
                elif v is None:
                    continue
                elif c.get("t") == "s":
                    val = strings[int(v.text)]
                else:
                    val = v.text
                cells.append(f"{c.get('r')}={val}")
            if cells:
                print("  ".join(cells))
                shown += 1
                if shown >= max_rows:
                    print("  ... (more rows)")
                    break


if __name__ == "__main__":
    dump(sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 40)