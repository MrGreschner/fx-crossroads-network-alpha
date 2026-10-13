# v154 — create, test, share, improve

## Where to find it

**Studio → Projects & Showcase** opens a unified creation journey. All six Labs have a Journey button. **Adventures → Build, trade & create → Community Showcase** lets ordinary players reach the featured creations directly. The Elder Ram explains the workflow.

## For students and creators

1. Build in any Lab and save/finalize the project.
2. Open My projects. Play/Test the creation in an isolated sandbox; hero, ability, enemy, behaviour and realm tests record duration and damage for that exact design. Object inspections are explicitly creator-reported visual checks.
3. Finalize the revision. The progress bar shows saved, tested, finalized, shared, feedback and improvement stages. It is not a grade.
4. Share submission: use a class alias and a short description of what to try. This freezes the project, matching test receipts and a version number. Download and send the submission JSON to your reviewer.
5. Import the returned feedback JSON, read the next step and edit a copy. Testing and finalizing the changed copy leads to a new submission version. Editing never mutates an older submission.
6. Download Profile before changing computers. The ZIP includes creations, frozen submissions, feedback and imported Showcase entries.

## Teacher curation

Open Teacher Class View → Creation review & Showcase, or the Teacher curation tab in the new interface. Import creation submissions, play/test the frozen project, review its evidence and permissions, then approve it or request a revision. Add your reviewer alias and a useful next step. Download the updated submission file to return feedback.

Class View can also nominate a creation from a student's frozen curriculum submission. This only puts it in the curation queue: test and review it before approval. Showcase approval is a publication decision, not a curriculum mark. Teacher review explains observed test data, student intent and teacher judgement separately.

Download approved Showcase pack. Students import that JSON in Projects & Showcase to play its entries. Two clearly labelled built-in demonstrations show what an entry looks like. They are not represented as student work.

For a featured release, replace **content/workshop/showcase.json** with your exported approved pack, then export Web and Windows. This is a curated file-based gallery. No central upload database or authenticated online publisher was added; share trusted classroom files. Original creator files remain local.

## Stability changes

- Studio library and drafts use temporary-file replacement and last-good backups.
- Library recovery validates the backup and tells the creator when recovery occurred.
- A schema-invalid existing library cannot overwrite its good backup during replacement.
- Hero artwork textures are reused when artwork is unchanged; obsolete custom hero poses are removed when a hero leaves the library.
- Tests/submissions are matched to a design fingerprint. A changed design needs a new test; additional reports do not themselves change the design identity.
- Importing feedback retains existing feedback and checks the frozen revision identity. Importing a submission does not publish it.
- Previews behind the Showcase are hidden/suspended. Sandbox tests do not replace an open draft or earn combat progression.
- Limits keep 20 frozen submission snapshots and 20 imported Showcase entries; export and remove older snapshots when needed. Existing project-library limits remain. The creation journey fits within an 8 MB cap and the full Studio library within 16 MB.

The base official hero attacks and realm progression are unchanged. v152 and v153 features remain included.
