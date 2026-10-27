# V230 town cast

Built-in ImageGen used for six selected transparent sprite sheets (108 poses / 36 designs). Existing project Ram, Medic, Reed, Prism and Cat sprites were style references; existing guards, farmer and fishing keeper were identity references. Prompts are saved verbatim in tools/town230_prompts.json. These are graphical upgrades to existing townspeople, not new gameplay characters.

Selected ImageGen source IDs:
- residents0: dd43342b-a761-47a8-95e9-ce7fd1dcdde5
- residents1: acaf2b33-6da5-47e5-8d8f-2c3ebd509d0e
- residents2: f7170773-4572-4aa5-ad88-f6377d66d140
- keepers: babc499c-ecda-47c3-9ce2-c734770fbc5d
- specialists0: df3f2d52-d506-4872-b771-590808901445
- specialists1: 96c2fde1-5820-47de-bde0-056535c79ed7

Original selected sheets: assets/town230/*_source.png. Runtime atlas: assets/town230/citizens.png. Transparent gutters, source crop rectangles, walking offsets and visible world heights are recorded in assets/town230/manifest230.json. tools/prepare_town230.py reproduces the technical cropping, normalization and registration. No generated sheet is loaded or processed per frame.

The first three block-like drafts were rejected and are not included in the project. The inactive intro arch fix changes native shader alpha and browser canvas drawing, with no scenery artwork alteration.
