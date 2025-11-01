from pathlib import Path

for xml_file in Path('mod').glob('**/*.xml'):
    content = xml_file.read_text(encoding='utf-8')
    xml_file.write_text(content.replace('\t', '    '), encoding='utf-8')
    print(f'Formatted: {xml_file}')
