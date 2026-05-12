#!/usr/bin/env python3
"""BRD PDF Requirement Extractor - Parses BRD/FRD PDF and extracts structured requirements."""
import argparse, json, os, re, sys
from datetime import datetime
try:
    import pdfplumber
except ImportError:
    print("ERROR: pdfplumber not installed. Run: pip install pdfplumber --break-system-packages"); sys.exit(1)

REQ_ID_PATTERNS = [
    re.compile(r'(REQ[-_]\d{1,4}(?:\.\d+)?)', re.IGNORECASE),
    re.compile(r'(FR[-_]\d{1,4}(?:\.\d+)?)', re.IGNORECASE),
    re.compile(r'(BR[-_]\d{1,4}(?:\.\d+)?)', re.IGNORECASE),
    re.compile(r'(UC[-_]\d{1,4}(?:\.\d+)?)', re.IGNORECASE),
    re.compile(r'(NFR[-_]\d{1,4}(?:\.\d+)?)', re.IGNORECASE),
]
REQUIREMENT_STARTERS = [
    re.compile(r'(?:The\s+)?system\s+(?:shall|must|will|should)\s+', re.IGNORECASE),
    re.compile(r'(?:The\s+)?application\s+(?:shall|must|will|should)\s+', re.IGNORECASE),
    re.compile(r'(?:The\s+)?platform\s+(?:shall|must|will|should)\s+', re.IGNORECASE),
    re.compile(r'(?:The\s+)?solution\s+(?:shall|must|will|should)\s+', re.IGNORECASE),
    re.compile(r'Users?\s+(?:shall|must|will|should)\s+be\s+able\s+to\s+', re.IGNORECASE),
]
NUMBERED_PATTERN = re.compile(r'^\s*(\d{1,2}\.\d{1,2}(?:\.\d{1,2})?)\s+(.+)')
BULLET_PATTERN = re.compile(r'^\s*[\u2022\u25cf\u25cb\u25aa\-\*]\s+(.+)')
SECTION_HEADER_PATTERNS = [
    re.compile(r'^(\d{1,2}\.?\s+[A-Z][A-Za-z\s&,\-/]+)$'),
    re.compile(r'^(\d{1,2}\.\d{1,2}\s+[A-Z][A-Za-z\s&,\-/]+)$'),
    re.compile(r'^([A-Z][A-Z\s&,\-/]{3,60})$'),
]
PRIORITY_KW = {"high": ["must", "critical", "mandatory", "required", "essential", "shall"],
               "medium": ["should", "important", "expected", "needed"],
               "low": ["could", "nice to have", "optional", "may", "desired"]}

def detect_priority(text):
    tl = text.lower()
    for p, kws in PRIORITY_KW.items():
        for kw in kws:
            if kw in tl: return p
    return "medium"

def extract_req_id(text):
    for p in REQ_ID_PATTERNS:
        m = p.search(text)
        if m: return m.group(1).upper()
    return None

def is_starter(text):
    for p in REQUIREMENT_STARTERS:
        if p.search(text): return True
    return False

def detect_section(text):
    t = text.strip()
    for p in SECTION_HEADER_PATTERNS:
        m = p.match(t)
        if m and len(t) < 80: return m.group(1).strip()
    return None

def parse_brd(pdf_path):
    print(f"  Opening: {pdf_path}")
    reqs, current_section, auto_id, seen = [], "General", 0, set()
    with pdfplumber.open(pdf_path) as pdf:
        print(f"  Pages: {len(pdf.pages)}")
        all_lines = []
        for i, page in enumerate(pdf.pages):
            text = page.extract_text() or ""
            for line in text.split("\n"):
                line = line.strip()
                if line and len(line) >= 5:
                    all_lines.append({"text": line, "page": i+1, "section": None})
        # Assign sections
        for ld in all_lines:
            s = detect_section(ld["text"])
            if s: current_section = s
            ld["section"] = current_section
        print(f"  Lines: {len(all_lines)}")
        # Extract requirements
        i = 0
        while i < len(all_lines):
            ld = all_lines[i]
            text, page, section = ld["text"], ld["page"], ld["section"]
            req_id = extract_req_id(text)
            is_req = is_starter(text)
            nm = NUMBERED_PATTERN.match(text)
            if nm:
                is_req = True
                if not req_id: req_id = f"REQ-{nm.group(1)}"
            if req_id or is_req:
                full = text
                j = i + 1
                while j < len(all_lines):
                    nl = all_lines[j]["text"]
                    if extract_req_id(nl) or detect_section(nl) or NUMBERED_PATTERN.match(nl) or is_starter(nl): break
                    if len(nl) > 10 and not nl.endswith(":"): full += " " + nl; j += 1; continue
                    break
                full = re.sub(r'\s+', ' ', full).strip()
                key = full[:100].lower()
                if key not in seen:
                    seen.add(key)
                    if not req_id: auto_id += 1; req_id = f"REQ-{auto_id:03d}"
                    reqs.append({"id": req_id, "text": full, "section": section, "page": page, "priority": detect_priority(full)})
                i = j; continue
            bm = BULLET_PATTERN.match(text)
            if bm and len(text) > 30:
                action_kw = ["must","shall","should","will","need","allow","enable","support","provide",
                             "display","create","update","delete","send","notify","calculate","validate",
                             "restrict","automate","capture","track","store","generate","integrate"]
                if any(k in text.lower() for k in action_kw):
                    key = text[:100].lower()
                    if key not in seen:
                        seen.add(key); auto_id += 1
                        reqs.append({"id": f"REQ-{auto_id:03d}", "text": bm.group(1), "section": section, "page": page, "priority": detect_priority(text)})
            i += 1
    return reqs

def main():
    ap = argparse.ArgumentParser(description="Extract requirements from BRD PDF")
    ap.add_argument("--pdf", required=True); ap.add_argument("--output", required=True)
    args = ap.parse_args()
    if not os.path.exists(args.pdf): print(f"ERROR: Not found: {args.pdf}"); sys.exit(1)
    os.makedirs(os.path.dirname(args.output) or ".", exist_ok=True)
    print(f"\n{'='*60}\nBRD Requirement Extractor\n{'='*60}")
    reqs = parse_brd(args.pdf)
    data = {"source": os.path.basename(args.pdf), "extracted_at": datetime.now().isoformat(),
            "total_requirements": len(reqs), "sections": list(set(r["section"] for r in reqs)), "requirements": reqs}
    with open(args.output, "w") as f: json.dump(data, f, indent=2)
    bp = {}
    for r in reqs: bp[r["priority"]] = bp.get(r["priority"], 0) + 1
    print(f"\n  Requirements: {len(reqs)}")
    print(f"  Sections: {len(data['sections'])}")
    for p, c in sorted(bp.items()): print(f"    {p}: {c}")
    print(f"  Output: {args.output}\n{'='*60}\n  Done!\n{'='*60}\n")

if __name__ == "__main__": main()
