import os
from os import path
import shutil
from tqdm import tqdm
import xml.etree.ElementTree as ET
import wikitextparser as wtp


SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
OUTPUT_DIR = path.join(SCRIPT_DIR, "data")

shutil.rmtree(OUTPUT_DIR, ignore_errors=True)
os.mkdir(OUTPUT_DIR)

# Download the XML file from:
# https://starwars.fandom.com/wiki/Special:Statistics
print("Loading XML file...")
tree = ET.parse('/home/loryruta/Desktop/asdfsafd/starwars_pages_current.xml')
root = tree.getroot()

ns = "{http://www.mediawiki.org/xml/export-0.11/}"

def character_filename(character_name: str) -> str:
    character_name = character_name.replace("/", "_")
    character_name = character_name.replace(" ", "_")
    return f"{character_name}.txt"

num_pages = 0
num_characters = 0
num_children = len(root)
progress_bar = tqdm(enumerate(root))
for i, child in progress_bar:
    # {http://www.mediawiki.org/xml/export-0.11/}page
    if child.tag == f"{ns}page":
        page_content = child.find(f"{ns}revision").find(f"{ns}text").text
        if type(page_content) != str:
            continue  # Page without text
        num_pages += 1
        parsed_page = wtp.parse(page_content)
        character_template = None
        for template in parsed_page.templates:
            if template.name.strip() == "Character":
                character_template = template
                break
        if character_template is None:
            continue  # Not a character page
            
        character_name = child.find(f"{ns}title").text
        if character_name.startswith("User:"):
            continue  # User?
        if character_name.endswith("/Legends"):
            continue  # Who cares about StarWars Legends characters!?
    
        page_text = ''
        has_biography = False
        for section in parsed_page.sections:
            if (section.title is not None) and (section.title.strip() == "Biography"):
                has_biography = True
            if section.title is None or section.title.strip() not in [
                "Behind the scenes",
                "Appearances",
                "Non-canon appearances",
                "Sources",
                "Notes and references",
                "External links"
                ]:
                page_text += section.plain_text().strip() + "\n\n"
        if not has_biography:
            continue  # A proper Character has at least a Biography section!
        if page_text == "" or page_text is None:
            continue  # Nothing about this character
            
        with open(path.join(OUTPUT_DIR, character_filename(character_name)), "wt") as f:
            f.write(page_text)
        num_characters += 1

print(f"Generated a dataset of size: {num_characters}");
