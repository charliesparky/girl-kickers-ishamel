#!/usr/bin/env python3
"""
Script to generate GIRL variants from base definitions.

This script automates the generation of:
1. GIRL entity variants (gfl_humans_girl.xml) from base entities (gfl_humans.xml)
2. GIRL unit definition (gfl_unit_girl.xml) from base units (gfl_unit.xml)

Usage:
    python generate_girls.py [--entities] [--units] [--all]

    --entities    Generate only entity variants
    --units       Generate only unit definition
    --all         Generate both (default if no option specified)
"""

import re
import sys
from pathlib import Path


def generate_girl_entities(input_file, output_file):
    """Generate GIRL entity variants from base entities."""
    print(f"\n=== Generating GIRL Entities ===")
    print(f"Reading entities from: {input_file}")

    with open(input_file, "r", encoding="utf-8") as f:
        content = f.read()

    entity_pattern = r'(<Entity name="([^"]+)".*?</Entity>)'
    entities = re.findall(entity_pattern, content, re.DOTALL)

    base_entities = []
    for entity_xml, entity_name in entities:
        if not entity_name.startswith("GIRL-"):
            base_entities.append((entity_name, entity_xml))

    print(f"Found {len(base_entities)} base entities")

    girl_entities = []
    for entity_name, entity_xml in base_entities:
        match = re.match(r"[A-Z0-9]+-(.+)", entity_name)
        if not match:
            raise ValueError(
                f"Entity name '{entity_name}' does not match expected pattern 'PREFIX-NAME'"
            )

        suffix = match.group(1)
        new_entity_name = f"GIRL-{suffix}"

        new_xml = entity_xml.replace(
            f'name="{entity_name}"', f'name="{new_entity_name}"', 1
        )

        new_xml = re.sub(r'unit="GFL-UNIT-[^"]*"', 'unit="GFL-UNIT-GIRL"', new_xml)

        girl_entities.append((new_entity_name, new_xml))
        print(f"  {entity_name} -> {new_entity_name}")

    print(f"Writing GIRL entities to: {output_file}")
    with open(output_file, "w", encoding="utf-8") as f:
        f.write("<Entities>\n")
        for _, entity_xml in girl_entities:
            f.write("\t" + entity_xml + "\n\n")
        f.write("</Entities>\n")

    print(f"✓ Generated {len(girl_entities)} GIRL entities")


def generate_girl_unit(input_file, output_file):
    """Generate GFL-UNIT-GIRL unit definition from all base units."""
    print(f"\n=== Generating GIRL Unit ===")
    print(f"Reading units from: {input_file}")

    with open(input_file, "r", encoding="utf-8") as f:
        content = f.read()

    class_pattern = r'(<Class\s+name="GFL-DOLL-[^"]+"\s+nameUI="[^"]+"\s+description="[^"]+"\s+numSlots="[^"]+"\s+supply="[^"]+"\s+iconTex="[^"]+"\s+upgrades="[^"]+"\s+maxUpgradeable="[^"]+"\s*/>)'

    classes = re.findall(class_pattern, content, re.DOTALL)
    print(f"Found {len(classes)} class definitions")

    formatted_classes = []
    for class_xml in classes:
        indented = "\t\t\t" + class_xml
        formatted_classes.append(indented)

    classes_str = "\n".join(formatted_classes)

    template = """<Units>
    <Unit
        name="GFL-UNIT-GIRL"
        nameUI="@GFL-UNIT-GIRL-NAME"
        description="@GFL-UNIT-GIRL-DESC"
        flagTex="data/textures/gfl_girl_bg.dds"
        flagColor="E3F6FD"
        movie="data/movies/gfl_unlock_girl.ogv"
        rndNameEntry="@#GFL-UNIT-GIRL-NAME-RND"
        voicepack="commander_eng"
        incapacitationChance="60"
        incapacitationChanceCrit="30"
    >
        <Classes>
{classes}
        </Classes>

        <TrooperRanks>
            <Rank
                name="@agent_rank_0"
                xpNeeded="0"
                badgeTex="data/textures/gui/customization/cia_rank_01.dds"
            />
            <Rank
                name="@agent_rank_1"
                xpNeeded="700"
                badgeTex="data/textures/gui/customization/cia_rank_02.dds"
            />
            <Rank
                name="@agent_rank_2"
                xpNeeded="2300"
                badgeTex="data/textures/gui/customization/cia_rank_03.dds"
            />
            <Rank
                name="@agent_rank_3"
                xpNeeded="5600"
                badgeTex="data/textures/gui/customization/cia_rank_04.dds"
            />
            <Rank
                name="@agent_rank_4"
                xpNeeded="11800"
                badgeTex="data/textures/gui/customization/cia_rank_05.dds"
            />
            <Rank
                name="@agent_rank_5"
                xpNeeded="22400"
                badgeTex="data/textures/gui/customization/cia_rank_06.dds"
            />
            <Rank
                name="@agent_rank_6"
                xpNeeded="38400"
                badgeTex="data/textures/gui/customization/cia_rank_07.dds"
            />
            <Rank
                name="@agent_rank_7"
                xpNeeded="60200"
                badgeTex="data/textures/gui/customization/cia_rank_08.dds"
            />
            <Rank
                name="@agent_rank_8"
                xpNeeded="86400"
                badgeTex="data/textures/gui/customization/cia_rank_09.dds"
            />
            <Rank
                name="@agent_rank_9"
                xpNeeded="126400"
                badgeTex="data/textures/gui/customization/cia_rank_10.dds"
            />
        </TrooperRanks>

        <Ranks>
            <Rank xpNeeded="0" badgeTex="" />
            <Rank xpNeeded="4000" badgeTex="" />
            <Rank xpNeeded="9000" badgeTex="" />
            <Rank xpNeeded="14980" badgeTex="" />
            <Rank xpNeeded="21920" badgeTex="" />
            <Rank xpNeeded="29800" badgeTex="" />
            <Rank xpNeeded="38600" badgeTex="" />
            <Rank xpNeeded="48310" badgeTex="" />
            <Rank xpNeeded="58900" badgeTex="" />
            <Rank xpNeeded="70360" badgeTex="" />
        </Ranks>
    </Unit>
</Units>
"""

    output_content = template.format(classes=classes_str)

    print(f"Writing GIRL unit to: {output_file}")
    with open(output_file, "w", encoding="utf-8") as f:
        f.write(output_content)

    print(f"✓ Generated GFL-UNIT-GIRL with {len(classes)} classes")


def main():
    args = sys.argv[1:]
    generate_entities = "--entities" in args or "--all" in args or len(args) == 0
    generate_units = "--units" in args or "--all" in args or len(args) == 0

    script_dir = Path(__file__).parent
    project_dir = script_dir.parent

    entities_input = project_dir / "mod" / "entities" / "gfl_humans.xml"
    entities_output = project_dir / "mod" / "entities" / "gfl_humans_girl.xml"

    units_input = project_dir / "mod" / "units" / "gfl_unit.xml"
    units_output = project_dir / "mod" / "units" / "gfl_unit_girl.xml"

    if generate_entities:
        generate_girl_entities(entities_input, entities_output)

    if generate_units:
        generate_girl_unit(units_input, units_output)


if __name__ == "__main__":
    main()
