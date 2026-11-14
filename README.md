# Arth

A mobile PDF/EPUB reader for Hindi-speaking readers of English books. Tap a word or select
a sentence and get the Hindi meaning — explained in plain Hindi, for *this* sentence.

```
app/        Flutter app (Phase 4)
api/        Fastify + Mongoose API — /v1/lookup, /v1/context, /v1/translate, /v1/phrases/match
pipeline/   Python dictionary build: Wiktionary → LLM batch → Mongo (Phase 2)
contracts/  JSON Schemas, normalization spec + test vectors shared by all three
```

## Status

- [x] Phase 1 — contracts + API skeleton (`/v1/lookup` on a 22-entry hand-written seed)
- [x] Phase 2 — pipeline; full 23k-entry build on luna loaded to Atlas ($8.10 real cost)
- [x] Phase 3 — `/context`, `/translate` (SSE), `/phrases/match`, content-hash cache, index-only experiment behind `CONTEXT_MODE`
- [x] Phase 4 — Flutter app (reader + tooltip verified on a real PDF; /context and /translate light up with Phase 3)
- [x] Phase 5 — full-size build, prefetch, per-device rate limits, gzip seed, bilingual UI, error/empty states, attribution

## Setup

Prereqs: Node ≥ 20.6, a MongoDB Atlas cluster, Flutter 3.x, Python 3.11.

### API

```sh
cd api
cp .env.example .env          # set MONGODB_URI to the Atlas connection string (database: arth)
npm install
npm run seed                  # loads seed/seed.json (idempotent upserts)
npm run dev                   # http://localhost:3000

curl 'localhost:3000/v1/lookup?word=fortune'
curl 'localhost:3000/v1/lookup?word=Wives'      # → wife, via lowercase + forms
curl 'localhost:3000/v1/lookup?word=in%20want%20of'
curl -X POST localhost:3000/v1/context -H 'content-type: application/json' \
  -d '{"word":"single","sentence":"It is a truth universally acknowledged, that a single man in possession of a good fortune, must be in want of a wife."}'
curl -N -X POST localhost:3000/v1/translate -H 'content-type: application/json' -d '{"text":"It is a truth universally acknowledged."}'   # SSE
curl -X POST localhost:3000/v1/phrases/match -H 'content-type: application/json' -d '{"tokens":["must","be","in","want","of"],"index":3}'
```

`/context` and `/translate` need `OPENAI_API_KEY` in `api/.env`. Every LLM call goes through
`src/llm/provider.ts`; results are cached forever in the `cache` collection by content hash
(`contracts/normalize.md`), with an in-process LRU in front. `/v1/health` reports the hit rate.
`CONTEXT_MODE=index` switches `/context` to the index-only path (model classifies, note comes
from `senseNotes` written by `pipeline/07_notes.py`); `npm run bench:context` compares both.

Tests (no Mongo needed — lemma resolution runs on an in-memory store):

```sh
npm test          # normalize vectors, lemma resolution, /lookup route, seed validation
npm run typecheck
```

Both `api/` and `pipeline/` read the same `MONGODB_URI`; the database name is the path segment of the URI and should be `arth`.

### Pipeline

```sh
cd pipeline
python3.11 -m venv .venv && .venv/bin/pip install -e '.[dev]'
cp .env.example .env          # add OPENAI_API_KEY and the same MONGODB_URI as api/
.venv/bin/pytest              # 69 tests: normalize vectors, generation validation + retry
.venv/bin/python 01_download.py && .venv/bin/python 02_select.py --n 500 && .venv/bin/python 03_extract.py
```

See `pipeline/README.md` for the generate → load steps and the review reports.

### App

```sh
cd app
flutter pub get
python3 tool/gen_models.py && dart run build_runner build -d   # only after a contracts/ change
flutter test && flutter analyze

# A phone can't reach localhost on the Mac: pass the LAN IP (or set it later in Settings → सर्वर).
flutter run --release -d <device-id> --dart-define=ARTH_API_URL=http://192.168.x.x:3000

# Simulator smoke test: import a PDF (or .epub) automatically and drive the reader over the VM service.
# The iOS simulator can't link ML Kit; use an Android emulator (host is 10.0.2.2 there).
flutter run -d <emulator-id> --dart-define=ARTH_API_URL=http://10.0.2.2:3000 \
  --dart-define=ARTH_DEV_PDF_URL=http://10.0.2.2:8765/book.pdf
```

The interface is English by default; **You → Interface language** switches to Hindi. Dictionary
content is always Hindi. Strings live in `app/lib/app/strings.dart`.

Debug builds expose `ext.arth.nav / tapWord / select / dismiss / state` VM-service
extensions (`app/lib/app/dev_hooks.dart`) so the tooltip can be exercised on a
simulator without touch automation. App icon: `python3 tool/make_icon.py`.

### Contracts

`contracts/` is the source of truth for wire types and text normalization. See
`contracts/README.md`. Every language's `normalize()` must pass
`contracts/normalize-vectors.json` — TypeScript (`api/test/normalize.test.ts`) and Python
(`pipeline/tests/test_normalize.py`) do; Dart is added in Phase 4.

## EPUBs

Library → **+** → *Add a PDF or EPUB*. An EPUB is opened in place from the zip
(`app/lib/core/epub/epub_book.dart`: container → OPF spine → EPUB 3 nav or NCX table of
contents), and each chapter's XHTML is parsed off the main isolate into text blocks
(`epub_html.dart`: paragraphs, headings, quotes, lists, `pre`; emphasis kept, images dropped).
`EpubReaderScreen` lays the blocks out as a scrolling column, one chapter per swipe, painting
each block with its own `TextPainter` (`epub_paragraph.dart`) so the word rects handed to the
tooltip are exactly where the glyphs are; a block is the unit for `PageTextIndex`, so sentences
never cross a paragraph. The Contents sheet jumps by title; `lastPage` is the chapter and the
scroll offset is kept in the kv table. Same tooltip layer, `/context` and `/translate` as the PDF
reader; no drag selection (the word card's translate action handles the sentence) and no prefetch.

## Highlighter

Four colours, saved per book in the `highlights` table (`app/lib/data/local_store.dart`, schema
v3) as `(page, block?, startWord, endWord)` — word indices in the page's (PDF) or block's (EPUB)
`PageTextIndex`, which are deterministic for a given file — plus the text for the list. Shared
pieces live in `app/lib/features/reader/highlights/`: the palette, the colour bar, and the
per-book Highlights sheet (reader ⋮ menu → Highlights: jump to a highlight, remove one).

- **EPUB**: press and hold a word and drag to extend within the paragraph; release for the
  colour bar (translate is there too). Long-press an existing highlight to recolour or remove
  it. Bands are painted by the block's render object under the text.
- **PDF**: select text (pdfrx's long-press selection); the translation card gets a *Highlight*
  colour row. The selection is mapped to word indices by matching its first and last tokens
  near pdfrx's character offsets; bands are drawn in the viewer overlay from rects resolved
  for pages near the current one.
- The word card's translate action also offers the colour row for that sentence.
- Not on scans: OCR word positions aren't stable enough to anchor to.

## Photographed pages (scan reader)

Library → **+** → *Take a photo of a page* / *Choose a photo from gallery*. The photo is OCR'd on
the device with Google ML Kit (Latin script, offline; `app/lib/data/ocr_service.dart`, result
cached beside the image), indexed with `PageTextIndex.fromLines`, and shown in
`ScanReaderScreen` with the same tooltip layer as the PDF reader
(`app/lib/features/reader/tooltip/tooltip_layer.dart`). Tap a word; the word card's translate
action handles the sentence. A scan is a book of pages under `Documents/scans/<id>/`; *Add a
page* from the reader's app bar. iOS deployment target is 15.5 (ML Kit). ML Kit's iOS pods have
no Apple-Silicon simulator slice — test scans on a device.

## Expanding the dictionary on demand

`pipeline/08_stage.py` stages Wiktionary senses (English only) for ~90k lemmas beyond the
generated 23k — the whole `wordfreq` list plus every attested Wiktionary headword — into the
`wiktionary` collection. When `/v1/lookup` misses `entries` but the lemma is staged, the API
generates its Hindi layer live with the pipeline's prompt and validation, stores it in
`entries` for good and returns it (3–7 s the first time, instant after).

Under that sits a second fallback, for the words no word list ever had: hyphenated and open
compounds (`decision-making`, `rank-and-file`), derived words (`unrepentantly`), terms of
trade, Indian English (`prepone`, `eve-teasing`). Nothing is staged for them, so there are no
senses to translate — the model writes the senses as well as the Hindi, against
`contracts/prompts/unknown-system.md`, and the entry is filed under `tier: 'coined'` with a
`freqRank` past every real one so it is served by `/lookup` but downloaded by no phone.

That prompt's first instruction is to return **no senses at all** for anything it does not
recognise — a name, a scanning error (`rnoming`), another language — because a reader is far
better served by "not in the dictionary" than by an invented meaning. Measured against
gpt-5.6-luna: `keith`, `teh` and `mehtras` are declined in ~1 s; `decision-making`,
`stoichiometry` and `eve-teasing` are written in ~4 s. A declined word is remembered in the
`cache` collection, so the second reader to tap it pays nothing, and the reader's AI use is
refunded. Tokens that aren't word-shaped (digits, dots, under four letters) never reach the
model at all.

A word that both paths give up on gets a 404 whose `suggestions` are morphological bases
(`brimlessness` → `brimless`, `brim`). Generation spends the per-device LLM budget like any
model call.

## How many meanings a word gets

`config.max_senses_per_entry` (pipeline) caps the senses one headword keeps. It was **8**,
and 4,080 of the 23,001 entries — 18%, and exactly the words readers tap most (`get`, `set`,
`run`, `up`, `out`) — sat on that cap, which is why "get" showed eight meanings where Oxford
shows forty. It is now **25**.

Which senses survive, and in what order:

- `wiktionary.py:DROP_SENSE_TAGS` drops a sense outright for one of two reasons only: nobody
  writes that English any more (`obsolete`, `misspelling`), or the app cannot show it to a
  school student beside an ad (`vulgar`, `offensive`, `derogatory`).
- **Slang, informal, humorous, rare, dialectal and nonstandard senses are kept** and labelled.
  They used to be dropped or docked 8 points, which with 8 slots meant they were never seen.
- `03_extract.py:RANK_PENALTY` only decides the *order*: archaic −5, rare −5, literary −3,
  slang −2, informal −1, and so on. One penalty per sense, the heaviest — a sense tagged both
  archaic and slang is not twice as obscure. A well-attested slang sense still outranks a
  plain sense nobody uses.
- `Sense.styleLabel` carries Wiktionary's own label into the app in Hindi — स्लैंग, अनौपचारिक,
  पुराना, ब्रिटिश, कम प्रचलित — shown beside the part of speech. It is **set from the tags, never
  written by the model**: the model is not even shown it, so it costs no tokens and cannot be
  invented. Entries written before style labels simply have none.

`RESTRICTED_TAGS` is a different question and did not change: not "may a reader see this
sense?" but "may this entry define a phrase, or say that one word is a form of another?".
A slang spelling (`geaux` → `go`) must never steer lemma resolution.

Re-running after a cap or tag change. `data/select-full.json` already holds the exact 23,001
headwords of the live dictionary, so only the extract is rebuilt — same words, new senses.
The dump is not in git (3.2 GB) and `01_download.py` is resumable:

```sh
cd pipeline
.venv/bin/python 01_download.py
.venv/bin/python 03_extract.py --in data/select-full.json --out data/extract-new.json
.venv/bin/python tool/diff_extracts.py                 # what actually changed, and what it costs
.venv/bin/python 04_generate.py --mode batch --words-file data/regenerate.txt
.venv/bin/python 05_load.py --in data/generated-new.jsonl
.venv/bin/python 08_stage.py                           # the ~90k staged lemmas share the cap
```

Only words whose **senses** changed need the model. A word that merely gained a style label
on senses it already had is patched in place — the label comes from Wiktionary, not from the
model, so re-generating it would be paying for Hindi we already have. `diff_extracts.py`
splits the two piles and prices the first. Phones pick the change up as the daily `since`
delta, not a fresh download.

## Idioms, slang and phrasal verbs

A multi-word entry (`get up`, `in want of`, `get cold feet`) has always been a full
`DictionaryEntry` with its own Hindi senses — there are ~3,000 — but nothing linked a word to
the phrases built on it, so they were reachable only by tapping the phrase inside a book. The
word screen now lists them, in two groups:

- **Phrasal verbs** — the headword plus particles and nothing else: `get up`, `get away with`.
- **Idioms and phrases** — anything else that uses the word: `get cold feet`, `in want of`.

The split is `phraseKind()`, written twice against one closed particle list
(`api/src/services/related-phrases.ts`, `app/lib/core/text/related_phrases.dart`) so a phrase
answered from the phone reads exactly like one answered by the server. Tapping a line opens
that phrase's own entry.

Nothing here is generated: it is the dictionary the reader already has, linked up. The app
answers from its own `phrases` table first — ~2,800 of the 3,000 are inside the on-device
slice — and only falls back to `GET /v1/phrases/of?word=get` when the phone has no dictionary
yet. An empty list is a normal answer, not a 404.

## Hard words on this page

Reader ⋮ → **Hard words on this page**: every uncommon word on the page in
front of the reader, in one list, rarest first, each with its Hindi meaning
already filled in. Tapping one opens exactly the card a tap on the word in
the text would — the sheet is a way in, not a second kind of answer. In all
three readers; an EPUB has no pages, so "this page" is the paragraphs
currently laid out.

Entirely offline: which words are hard is decided by `freqRank`, at the same
threshold the reader already uses to decide when a word is worth an AI answer
(`kAiOnRequestRank`), so the list and the tooltip agree about what counts as
common. `app/lib/features/reader/page_vocabulary.dart`:

- **A word the phone's dictionary doesn't have is the rarest of all**, not the
  least rare. The on-device slice is the commonest 20,000 words, so a miss
  means rarer than anything in it. Sorting those last put `refreshments` above
  `obsequious`, which is the opposite of the point.
- **A name is not vocabulary.** Dropped when it is capitalised mid-sentence,
  and also when it is capitalised *every* time it appears on the page **and**
  the dictionary has never heard of it — `Elizabeth` opens sentences too, and
  otherwise led the list. Both halves are needed: `Printed` at the head of the
  only sentence it is in is always capitalised as well, and it is a real word.
- Under four letters, or carrying a digit, and it is a preposition or a page
  number rather than something to learn.

## Idioms

Dictionary tab → **Idioms**. 2,241 English idioms that have a Hindi
meaning, definition and examples in the dictionary, selected by
`pipeline/09_idioms.py` from Wiktionary's own `idiomatic` sense tag. Nothing
is generated: the LLM is never called for this, at build time or at run time.

| | |
|---|---|
| **Today's ten** (`/idioms`) | Ten a day, one card at a time. The front is the phrase and what it means; turning it over shows it doing its job in a real sentence, with the Hindi underneath. Save, skip, next. |
| **Browse** (`/idioms/all`) | All of them, searchable in either language, with a filter for the ones kept. |
| **Practice** (`/idioms/practice`) | "Which meaning fits?" — the wrong answers are *other idioms' meanings*, so the choice is a real test rather than one plausible line among filler. Idioms the reader keeps getting wrong are asked first. |
| **One idiom** (`/idiom/:phrase`) | Meaning, it in a sentence, its register labels, and "the story behind it" where Wiktionary records an etymology (385 of the 2,241 — `cast pearls before swine` gets Matthew 7:6). |

Three things decide what a reader actually meets:

- **Which sense is the idiom.** `senseIndex` is not always 0. "peanut butter"
  is an idiom for spreading resources too thin and its first sense is the
  spread; a card showing sense 0 would teach nothing. The idiomatic sense is
  matched back to our entry by its gloss, and an idiom whose idiomatic sense
  did not survive step 3's cut is dropped — we have no Hindi for it.
- **What counts as an idiom.** Phrasal verbs are left out (the word screen
  already lists them under their headword), as are phrases built only from
  function words ("at all", "about to"), idiomatic adverbs and conjunctions
  ("at first", "so long as"), and anything tagged vulgar, offensive,
  euphemistic or neologism — "special military operation" is tagged
  euphemistic, and is a state's name for an invasion, not an idiom.
- **What comes first.** Two signals, because each alone gets it wrong.

  `weight` — how many languages Wiktionary's editors translated the phrase
  into — orders the list. A phrase has no frequency rank of its own, and
  `freqRank` is the rank of its *rarest word*, so ordering by it opens a list
  of two thousand with collocations: "keep good time" and "red face test"
  above "spill the beans", which is built from rarer words. freqRank only
  breaks ties now.

  `idiomaticity()` then acts as a floor, not an order: it counts the
  meaning-carrying words a phrase uses, and a phrase with fewer than two
  ("at first", "by the way", "on purpose") is a construction rather than
  something to learn, so it is left out of the day's draw and sorted to the
  back of the browse list. Repeats count — "eye for an eye" and "neck and
  neck" are idioms, and an earlier version that counted only *different*
  words rejected them.

  Ordering by idiomaticity itself was the first attempt and does not scale: it
  counts words, so over two thousand phrases it simply sorts the longest to
  the top. At 241 idioms the day's pool was 17% of the list and the bias did
  not show; at 2,241 it is under 2%.

  The day's ten are drawn from the best known unseen and then shuffled by the
  day's seed, so a reader meets good idioms on day one and a different ten
  tomorrow.

**Finding them while reading.** An idiom in a browse list is one a reader
has to go looking for; the point is to meet it in the book. Two things were in
the way, and both are fixed in `phrase_windows.dart` (mirrored in
`api/src/services/phrases.ts`):

- The matcher built windows of **two to four tokens**, enough for the 3,000
  phrases the dictionary shipped with. "hit the nail on the head" is six and
  "let the cat out of the bag" is seven, so a reader tapping inside either got
  the entry for `nail` or `cat`. `kMaxPhraseTokens` is now 9, which reaches all
  but four of the idioms we hold.
- **1,182 idioms have a slot** — "change one's mind", "serve someone right" —
  and never appear literally, so no window could ever match them at any cap.
  `patternMatches` treats the slot tokens as wildcards. A bare `one` is not a
  slot: in "kill two birds with one stone" it is a numeral.

Both cost one query per tap rather than one per window: 44 windows is 44 round
trips, so `phraseCandidates` fetches every phrase that could match any of them
at once, by first token.

**Phrasal verbs** ride on the same rows, marked `kind: "phrasal"` — 113 of
them, the ones already in the dictionary with a Hindi meaning. They are taught
the same way, share the screen, and the browse list filters between them. They
are exempt from the idiomaticity floor: "give up" scores 1 because `up` is a
function word, which is exactly the shape the floor rejects, and a phrasal verb
is not grammar. Step 11 still refuses them, because it chooses what to *pay a
model to write* and a phrasal verb there is a whole new entry — about 837 are
available if you want them.

**One a day.** `daily_idiom_reminder.dart` plans a fortnight of notifications
from the idioms already on the phone, at the hour in settings, each one that
day's first card so the notification and the Today's 10 screen agree. A
fortnight, because iOS caps an app at 64 pending notifications and the card
reminders want their share. No account, server or connection.

Seed and storage: `idioms` is a Mongo collection and a seed line type
(`{"t":"idiom",…}`), so idioms arrive with the dictionary and work offline.
An app older than this feature skips the unknown line. Progress (saved, seen,
right, wrong) lives in `idiom_progress` on the phone and is never touched by a
seed. Schema v12 — v11 is the same without `weight`, and a phone upgrading
from it weighs every idiom 0 until the next seed arrives.

```sh
cd pipeline
.venv/bin/python 09_idioms.py --extract data/extract-full.json
.venv/bin/python 10_load_idioms.py
```

### More idioms

The 3,000-phrase cap in `02_select.py` predates this feature, and only ~240 of
those phrases survive the rules above. Wiktionary attests about **9,400**
multi-word entries with an `idiomatic` sense that the dictionary does not
carry, and **6,996** of them are usable. `11_more_idioms.py` writes them in
the shape step 4 generates from, ranked by `phrase_weight` — the
translation-count signal 02_select already uses, so "thick as thieves" is
ranked above "Roma locuta est". Only phrases step 9 would go on to accept are
selected, so nothing is generated that the feature then discards.

Two of its rules had to be loosened to get there, because reusing the
dictionary's own phrase rules on idioms threw away the best-known idioms in
English:

- **`idiom_phrase_ok` replaces `02_select.phrase_ok`.** That function guards
  the *in-text phrase matcher*: it caps a phrase at four tokens and rejects
  one containing a placeholder (`one's`, `someone`), because the reader matches
  phrases literally in running text and "someone's" never appears there. On
  idioms it rejected 3,386 entries — 1,364 for a placeholder (`pull the wool
  over someone's eyes`, `hold one's horses`), 757 for length (`let the cat out
  of the bag`, `hit the nail on the head`, `at the drop of a hat`), and 980
  for `has_usable_sense(strict=True)`, which excludes a phrase whose senses are
  all "restricted" — but an idiom is *usually* informal or slang (`get a move
  on`, `in the buff`). `idiomatic_senses()` is the stronger test and is applied
  anyway. Nothing downstream minds: `phrase_windows` only ever builds windows
  of two to four tokens, so a longer or placeholder phrase is never looked up
  in running text. It sits inert in `phrases` and still appears on its words'
  screens, which is where a reader meets it.
- **`--include-unranked` keeps a phrase built on a word the dictionary lacks**,
  ranking it from the words that do resolve. A phrase inherits the frequency
  rank of its rarest word, and 1,526 idioms contain a possessive (`devil's`,
  `sheep's`) or a word outside the top-20k slice (`eggshells`, `hooky`,
  `haystack`) — so `wolf in sheep's clothing`, `tit for tat`, `child's play`
  and `needle in a haystack` were all dropped for want of a rank. Treating the
  unknown word as "rarer than everything" instead parks the phrase at the end
  of the dictionary, outside the seed slice, and the app's idiom list
  inner-joins `entries` — so it would load into Mongo and never reach a phone.

Capitalised phrases (`go Dutch`, `Dutch courage`, `Jane Doe` — 324 of them)
stay out: 05_load keys a phrase entry `normalize_sentence(word).lower()` while
step 9 keys an idiom by the extract's own spelling, so the two would not meet,
and lowercasing `go dutch` on a card is wrong.

**The seed slice.** `SEED_LIMIT` is a count, not a rank — the 20,000
*lowest-ranked* entries — so adding 6,996 entries pushes 6,000-odd dictionary
words out of it. At 20,000 the slice would end at rank 15,763 instead of
26,728, leaving 9,391 words (up from 3,001) and 606 idioms off-device. Those
words still work through on-demand `/lookup`, but not offline, and an idiom
whose entry is off-device never appears at all. **27,000** restores today's
coverage; **30,000** ships the whole dictionary. The cost is a few MB on a
seed download — an idiom entry is ~0.2 KB gzipped and a common-word entry
~0.7 KB.

Measured on a live probe: **$0.49 per 1,000 entries** at live rates, and
**$0.25 per 1,000** in batch. The first 2,000 cost **$0.51** — 6.1M input
tokens, 678k output, 3,082 senses, 2,000 of 2,000 returned and 3 retried live
for a stray English word in a Hindi field. All 6,996 cost about **$1.75**.

`batch-fetch` takes its input and output paths from the batch state file, so
it reads back the extract the batch was built from rather than whatever `--in`
defaults to; pass `--out` only to override what `batch-submit` recorded.

```sh
.venv/bin/python 11_more_idioms.py --n 100000 --include-unranked
.venv/bin/python 04_generate.py --mode batch-submit --in data/idioms-extract.json --name idioms
.venv/bin/python 04_generate.py --mode batch-status --name idioms
.venv/bin/python 04_generate.py --mode batch-fetch  --name idioms
.venv/bin/python 05_load.py --in data/idioms-generated.jsonl --extract data/idioms-extract.json
.venv/bin/python 09_idioms.py --extract data/extract-full.json data/idioms-extract.json
.venv/bin/python 10_load_idioms.py
```

Idiom entries are extracted with `plain_examples_only`, which drops
Wiktionary's citations instead of falling back to them. A citation is a line
lifted out of a book or a song — *"Too many joy rides in daddy's Jaguar / Too
many white lies"* — and on an idiom card the example **is** the lesson, so a
riddle is worse than nothing. Given no example the entry prompt writes a plain
one itself: *"She told a white lie to avoid hurting his feelings."* Of the
2,000 selected, 972 senses had a real usage example and 1,458 get a written
one. The dictionary's own extraction is unchanged — it keeps citations, which
is right for a word a reader met in a 19th-century novel.

Some citations carry their source *inside* the example text, so Wiktionary
never tagged them a quotation and the plain-only path let them through:
*"Only force of habit will explain why people today do honor to Christopher
Columbus." - New York Times, 1937*. `example_teaches()` drops those, and drops
a sentence that explains the phrase rather than using it (*To "walk the
straight and narrow" means to live a moral life*) — but only when the quoted
span is the headword, since *Do you have any idea what "tergiversate" means?
Beats me!* is a real use of "beats me". Three of 1,364 examples were
affected.

**`--extract` must name the extract the live `entries` were generated from.**
`senseIndex` is a position in that extract's sense ordering, and the orderings
differ between extracts — a different cap or a changed `RANK_PENALTY` reshuffles
them. Building the file from `extract-new.json` while Mongo still held entries
from `extract-full.json` pointed `cold turkey` at "the physiological effects of
such a withdrawal" instead of the withdrawal itself. So **re-run both steps after
any dictionary regeneration**, against the extract that produced it. The loader
skips a row whose index is past the end of its entry, and `IdiomRow.sense` falls
back to the first sense, so a mismatch is wrong rather than fatal — but it is
still wrong.

## Searching in Hindi

The dictionary only ever ran one way: `searchWords` is `word LIKE 'prefix%'`,
so a reader who knew *खुशामद* but not *curry favor* could not find it. The
meanings live inside each entry's JSON and `LIKE '%…%'` over 23,000 JSON blobs
is not a search, so `meaning_terms` indexes them: the short `meaning` of each
of an entry's first `kIndexedSenses` senses, split on spaces, the danda and the
punctuation glosses are written with. Not `definition`, which is a sentence and
would make every entry answer to "करना".

Typing Devanagari in the dictionary's search field searches that index
instead, commonest word first. The index is built from the entries already on
the phone when it upgrades, so nobody downloads 70 MB again: 23,000 entries
take about a second on a laptop, once.

## Tools: producing English, not only taking it in

Everything else in Arth is receptive — a book goes in, meanings come out. The
Tools section goes the other way, which is the half of a language a
reader-only app never reaches. They are reached from the dictionary tab,
where a reader already comes to look something up.

| | |
|---|---|
| **Translator** (`/tools/translate`, `POST /v1/english`) | Hindi in, natural English out — the reverse of `/translate`, for somebody who knows their meaning exactly and is missing only the words. Carries the vocabulary worth keeping and the same thing said formally, casually and directly, because the first English a learner is handed is rarely the one their situation wants. |
| **Spell check** (`/tools/spell`, `POST /v1/proofread`) | The reader's own English, corrected. Every fix quotes the words it replaces, so the editor underlines each one *where it happened* rather than listing them below — a correction you have to hunt for in your own text teaches nothing — and says why in Hindi. A fix whose `wrong` is not found in the text is dropped server-side, because it would underline nothing. |
| **Say It Right** (`/tools/say`) | Hear a word, say it back, see how close you got. No server: recognition is the phone's own (`speech_to_text`), so it costs nothing to run and works without an account. |

**What Say It Right actually measures.** A recogniser reports *words*, not
sounds. So the score can tell a reader that "thought" came out as "taught" —
which is exactly the mistake worth catching — but it cannot hear a thickened
vowel in a word it got right. `pronunciationScore` is edit distance over the
letters, with spaces dropped so a word the recogniser splits in two ("a bout"
for "about") still counts as one attempt. Three bands: clear, nearly, not yet.
The words come from the reader's own saved vocabulary where there are enough
of them, and the commonest part of the dictionary otherwise.

Permissions: `RECORD_AUDIO` and a `RecognitionService` query on Android
(without the query, Android 11+ reports no recogniser at all), and the two
usage strings on iOS.

## Speaking practice

`/tools/coach` — a short role-play the learner talks their way through, with
their own sentences put right as they go. Four scenes: a job interview, buying
something, the doctor, meeting someone.

**The phone does the listening and the speaking.** Its own recogniser, its own
synthesizer; all that crosses the wire is text. That is the whole reason this
is affordable — a measured four-turn interview was 4,118 input and 821 output
tokens on `gpt-5.6-luna`, about **₹0.08**, and a ten-turn conversation works
out near **₹0.28**. Speech-to-speech over the Realtime API would be audio
tokens for the whole call, which does not fit a ₹500-a-year subscription.

The cost of doing it this way is latency: the recogniser needs a pause to
finalise and the model needs a second to answer, so a turn is two to four
seconds. It is press-to-talk and says so, rather than pretending to be a call
that keeps stalling.

**What the recogniser heard is always shown before it is sent, and can be
edited.** On-device recognition of Indian-accented English mishears often
enough that a coach correcting a sentence the learner never said would be
worse than no coach — so nothing reaches the model until the learner has seen
it. That is the `checking` stage in `coach_session.dart`.

`POST /v1/coach` takes the scene, the conversation so far and the latest
sentence, and returns the next line (English and Hindi) plus `better` when the
learner's sentence needed it — which the prompt is told to leave out most of
the time, because a learner corrected on every turn stops speaking. The
history is replayed to the model as a real conversation rather than summarised
into the prompt: a coach that forgets its own last question ends the illusion.
A scene's opening line is fixed and cached, so it is paid for once, ever.

### The schema the model is given is not the contract

OpenAI's strict mode **refuses a schema with an optional property**, so
`schemaForModel` lists every property as required and makes the ones our
contract leaves optional nullable instead. Without it the call is rejected
outright — and a test against a fake provider never notices, which is how
both `/summary` and `/coach` were written broken and only found by calling the
real API. Our own Ajv validation still treats them as optional; the contract
is the truth and the transform is a concession to one API.

## Asking about a sentence, and about a page

Two endpoints for the wall a reader hits once the words have stopped being the
problem. Both are one validated JSON object cached forever by content hash —
`/translate` streams because a sentence's Hindi is wanted word by word, while
these are read whole.

| | |
|---|---|
| `POST /v1/grammar` | **How this sentence works**, in Hindi: its one-line shape, then the two or three things worth noticing, each tied to the exact words it is about. The translation beside it says what the sentence means; this says why "had been", what "that" points at, where the verb sits. On the selection tooltip, beside *Make card*. |
| `POST /v1/summary` | **What happened here** — the page told back in plain Hindi, as a paragraph, the beats in order, and who appears, because a reader coming back after a week has lost the names. In the reader's ⋮ menu. Bounded at 200–20,000 characters so one tap cannot cost a fortune. |

Both sit behind the same AI gate and spend as `/translate` and `/context`.

## Flashcards, bookmarks, progress

Cards are made while reading — *Make card* on the word card (word + its meaning in this
sentence) or the translation card (quote + translation), or ⋮ → *Add a note card* for the
reader's own idea — and remember where in the book they came from. The **Cards** tab has a deck
per book; a deck is a **recap**: its cards as a timeline in reading order, grouped by chapter,
with *Replay the book* (every card, in order) and *Practice* (due first, flip, rate; Leitner
boxes in `app/lib/features/cards/review_schedule.dart`). Finishing a book (97%) offers its recap.

The reader's ribbon bookmarks the current page (EPUB: the first paragraph on screen, which
survives font-size changes); ⋮ → *Bookmarks* lists them. `books.progress` is a 0–1 fraction —
for EPUBs it counts the scroll position within the chapter — and drives the library's
*Continue reading* card and per-book percentages. Tables: `flashcards`, `bookmarks` (schema v4+).

## Accounts and sync

Sign in (You tab) with Google or a phone number + SMS code, via Firebase Auth. The API accepts
the Firebase ID token as `Authorization: Bearer …`, creates the user on first sight (`users`
collection: profile, `role` user/admin, `tier` free/pro/super) and serves `GET/PATCH /v1/me`,
`POST /v1/me/avatar` (a signed Cloudinary upload ticket — the photo goes straight from the phone
to Cloudinary, the secret stays on the server) and `POST /v1/sync`.

Sync covers flashcards and bookmarks: rows carry UUIDs, `updatedAt` and tombstones; the newer
`updatedAt` wins; every accepted write takes the user's next sequence number and a device pulls
"everything after the sequence I last saw" (`api/src/services/accounts.ts`). A book is
identified across devices by a content key — SHA-256 of its size and first MiB
(`app/lib/core/book_key.dart`) — so a synced card attaches to the same book on another phone, even
one imported later. The app syncs on sign-in, on resume, a few seconds after an edit, and from
*Sync now*. On first sign-in, what's already on the phone joins the account.

Setup (accounts stay hidden until this is done):

1. Firebase console → create a project; enable **Authentication → Google** and **Phone**.
   Add an Android app (`com.zethyst.arth`, with the debug and release SHA-1/SHA-256 —
   `cd app/android && ./gradlew signingReport`) and an iOS app (`com.zethyst.arth`).
2. API: set `FIREBASE_PROJECT_ID` (and `CLOUDINARY_URL` for photos) in `api/.env` / Render.
3. App: pass the Firebase values as dart-defines (see `app/lib/app/firebase_setup.dart`), e.g.
   `flutter run --dart-define-from-file=firebase.json` (copy `app/firebase.json.example`) with the project's API keys, sender id,
   Android/iOS app ids, the iOS OAuth client id and the **Web** OAuth client id (Android's
   Google sign-in needs it to get an ID token).
4. iOS: copy `app/ios/Flutter/Firebase.xcconfig.example` to `Firebase.xcconfig` and fill in the
   reversed client id and encoded app id (URL schemes for the sign-in callbacks). Phone sign-in
   on a real iPhone also wants an APNs key uploaded to Firebase (else it falls back to reCAPTCHA).

## Tiers, AI allowance, ads

| Tier  | AI answers                     | Ads                  |
|-------|--------------------------------|----------------------|
| Free  | 100, lifetime                  | banners outside the reader |
| Pro   | 1,000 per calendar month (UTC) | none                 |
| Super | unlimited                      | none                 |

Only AI answers count: `/context` (meaning in this sentence), `/translate`, and a dictionary
entry generated live by `/lookup`. The on-device dictionary is always free. When accounts are on
(`FIREBASE_PROJECT_ID` set), those routes need sign-in; a use is reserved atomically before the
work and refunded when no AI answer was served (single-sense words, failures). Background
prefetch is free but only while allowance remains. Responses carry `x-ai-used` / `x-ai-limit` /
`x-ai-period`; `402 QUOTA_EXCEEDED` includes the usage. Limits: `AI_FREE_LIMIT`,
`AI_PRO_MONTHLY` (`api/src/services/quota.ts`). Without a Firebase project nothing is enforced.

Tiers are set by hand until there are payments and an admin screen:

```sh
cd api && npm run set-tier -- reader@example.com pro      # or a uid / phone; add --admin for the admin role
```

In the app, a signed-out or out-of-allowance reader sees *Sign in* / *See plans* where the AI
answer would be (`app/lib/features/plans/`); the You tab shows what's left. **Plans** compares
the tiers; *Ask for an upgrade* emails `ARTH_SUPPORT_EMAIL` (dart-define).

Ads (`app/lib/features/ads/ads.dart`): Google Mobile Ads, a banner above the tab bar on Library,
Dictionary and Cards for free/signed-out readers, never in a reader. Google's UMP consent form
runs first where the law requires it; content is capped at PG. Without configuration Google's
**test** units serve (safe to tap). For real ads:

- Full-screen interstitials (`app/lib/features/ads/interstitials.dart`), free tier only, at natural
  breaks: leaving a book read for 2+ minutes, finishing a Replay/Practice session. Never in the
  first 2 minutes after launch, at most one per 6 minutes (`AdPacing`); one is kept preloaded.
- Ad units: `--dart-define=ADMOB_BANNER_ANDROID=…` / `ADMOB_BANNER_IOS=…`,
  `ADMOB_INTERSTITIAL_ANDROID=…` / `ADMOB_INTERSTITIAL_IOS=…`
- App id: Android `ADMOB_APP_ID=…` in `android/key.properties`; iOS `ADMOB_APP_ID = …` in
  `ios/Flutter/Firebase.xcconfig` (overrides the test id in `AdMob.xcconfig`).
- Play Console: declare that the app contains ads; App Store: the privacy label.

## Discount codes

A coupon never sets a price. Google Play and the App Store own prices, and a server that
handed out its own would be selling outside the store. What a coupon does is **point at a
cheaper offer the stores already hold** and decide who may buy at it — so the reader still
sees a real store price in their own currency, and the purchase is an ordinary store purchase
that RevenueCat and the existing webhook already understand.

Redeeming is two steps, and the split is the point:

| | |
|---|---|
| `POST /v1/coupons/check` | The reader typed a code. Is it good for them, and which offer does it unlock? **Spends nothing** — a reader who checks a code and then changes their mind has not used it up. |
| `POST /v1/coupons/claim` | The store took the money. Only now is the redemption counted, keyed `code:uid`, so a retry is free. |

Both need sign-in: a coupon belongs to a reader, not a phone. The code is upper-cased and
stripped of everything but letters and digits, so `mayur 40`, `Mayur-40` and `MAYUR40` are one
code — typing a coupon off a WhatsApp message should not fail on a space.

Create the store offer **first**, then point a code at it:

1. **Google Play** → Subscriptions → the product → its base plan → *Add offer*. Give the offer
   a tag (e.g. `pro_yearly_40off`) and set eligibility to *Developer determined*. The app finds
   the `SubscriptionOption` carrying that tag and buys it.
2. **App Store Connect** → the subscription → *Subscription Prices* → *Promotional Offers*.
   Note the offer's identifier. RevenueCat signs it (`Purchases.getPromotionalOffer`) just
   before the purchase, so the subscription key must be uploaded to RevenueCat.
3. Point a code at them:

```sh
cd api
npm run coupon -- create MAYUR40 --tier pro --period yearly \
  --android pro_yearly_40off --ios pro_yearly_40off \
  --label "40% off the first year" --label-hi "पहले साल 40% छूट" \
  --max 1 --days 30 --for +919425610527 --note "asked for 500-700/yr on WhatsApp"

npm run coupon -- list
npm run coupon -- show MAYUR40      # with who used it, and when
npm run coupon -- off MAYUR40       # stop it working, keep the record
```

`--for` locks the code to one reader (uid, email or phone — they must have signed in once);
repeat it for a few. `--max` caps total uses, `--days` ends it, and one reader can use a code
once however many times they tap. Both routes sit behind the per-device limit
(`RATE_LIMIT_LOOKUPS`, 60/minute), so make codes long enough that guessing at that rate is
hopeless — `MAYUR40` is fine, `X1` is not.

In the app, **Plans → "Have a discount code?"** stays a quiet link until tapped, so a reader
with no code is never nudged to go hunting for one. An accepted code becomes a chip, the plan
it applies to shows the store's offer price with the old price struck through, and the period
switch jumps to the one the code is for. A code the API accepts but whose offer the store has
not published yet says so plainly rather than failing. `Plan Purchase` analytics carries
`coupon: true/false`.

Collections: `coupons` (`_id` = the code), `couponRedemptions` (`_id` = `code:uid`).

## Analytics

Mixpanel (`app/lib/data/analytics.dart`). Never book titles, words or sentences. Events:

| Event | Properties |
|---|---|
| `Screen Viewed` | `screen` (route pattern, e.g. `/word/:lemma`) |
| `Book Added` / `Book Opened` | `format` (pdf, epub, scan) |
| `Word Looked Up` | `from` (reader, dictionary), `found`, `source` (local, api), `phrase` |
| `AI Lookup` | `kind` (word, sentence) |
| `AI Blocked` | `kind`, `reason` (UNAUTHORIZED, QUOTA_EXCEEDED, QUOTA_PHONE) |
| `Card Created` | `kind`, `from_book` |
| `Deck Saved` | `cards` |
| `Plan Purchase` | `plan`, `yearly`, `outcome`, `coupon` |
| `Rating Asked` | — |
| `Rated` | `stars` (1–5) |

Every event carries `plan` and `language`. Signed-in readers are identified by Firebase uid.
Readers can opt out in Settings → Share usage stats. The project token is built in; debug builds
send nothing unless `--dart-define=MIXPANEL_DEBUG=true`. Data residency:
`--dart-define=MIXPANEL_SERVER_URL=https://api-eu.mixpanel.com` (or `api-in`).

- Play Console → Data safety, for **Analytics** (collected, not shared, optional, not ephemeral):
  *Personal info → User IDs*, *Financial info → Purchase history*, *App activity → App
  interactions*, *Device or other IDs*. Where a type is already declared (e.g. User IDs for
  accounts), add the Analytics purpose to it.

## Asking for a rating

`app/lib/features/rating/rate_app.dart`. Five stars of our own, then the store.

The platforms' own prompts are rationed and silent about it — Apple shows its sheet a few
times a year at most and may show nothing, Play's quota is undocumented — so a button the
reader just pressed cannot be built on one. Ours always opens, and a tapped star leads to
where a review is actually typed: `market://details?id=com.zethyst.arth` on Android (with
the Play web address behind it, and a `<queries>` entry in the manifest so the intent is
visible on Android 11+), and `https://apps.apple.com/app/id<id>?action=write-review` on
iOS, which opens the composer rather than the listing. Set the id with
`--dart-define=ARTH_APP_STORE_ID=…` once Arth is on the App Store; until then iOS falls
back to `in_app_review`'s `requestReview()`, which needs no id and may show nothing.

**When it asks** (`shouldAskForRating`, a pure function with its own test): never after the
reader has rated or declined for good; never within 120 days of the last ask; and only once
they have a 3-day reading streak **or** 45 minutes of reading behind them. The moment is
closing a book and landing back in the library — `_trackScreen` in `app/lib/app/app.dart`
watches the direction, because opening a book is the opposite of a good time. **You → Rate
Arth** opens the same sheet on demand.

Both doors are open at every rating: five stars still offers "tell us what's missing"
(WhatsApp, the same number as About), and one star still offers the store. Routing unhappy
readers away from the store is against the spirit of both stores' rules, and it makes the
rating meaningless.

## Push notifications

Firebase Cloud Messaging. What sends one (`api/src/push/notify.ts`), each in the phone's own
interface language, to every phone the reader is signed in on:

| When | Message | Opens |
|---|---|---|
| Cards are due (daily cron, at most once a day) | "5 cards are ready — most from “Emma”" | Cards |
| An admin changes their plan (`npm run set-tier`) | "You're on Pro now ✨" | Plans |
| 10 free AI answers left (or 50 of a Pro month), once | "10 AI answers left" | Plans |
| The reader taps *Send a test notification* (Profile) | "Notifications are working" | You |

The app registers its token only after sign-in is restored (`app/lib/data/push_service.dart`),
again when FCM rotates it or the language changes, and removes it on sign-out; the API keeps up
to ten phones per user and drops tokens FCM reports dead. While the app is open Android shows
the banner itself (a local notification), iOS presents its own. *Review reminders* can be turned
off in Profile.

Setup: `FIREBASE_SERVICE_ACCOUNT` (Firebase → Project settings → Service accounts → Generate new
private key; the JSON, or base64 of it) in `api/.env`, on Render's `arth-api`, and on the
`arth-review-reminders` cron job (in `render.yaml`, 13:00 UTC daily). iOS also needs the APNs key
uploaded to Firebase (setup guide §4) and a real device: the simulator can't receive pushes.

```sh
cd api && npm run review-reminders          # send today's reminders now
```

## Android release builds

Signing uses `app/android/key.properties` and `app/android/upload-keystore.jks` — both
gitignored, **back them up**: an app signed with a different key cannot update an
installed one. Without them the release build silently signs with the debug key.

```sh
cd app
flutter build apk --release --split-per-abi --dart-define=ARTH_API_URL=https://arth-neo.onrender.com   # sideload: app-arm64-v8a-release.apk
flutter build appbundle --release        --dart-define=ARTH_API_URL=https://arth-neo.onrender.com   # Play Store
```

R8 shrinking is on; keep rules live in `app/android/app/proguard-rules.pro`.

## Deploying the API (Render)

`render.yaml` at the repo root is a Blueprint: New → Blueprint in the Render dashboard, pick
this repo, set `MONGODB_URI` and `OPENAI_API_KEY` when prompted. Build is
`cd api && npm ci && npm run build`, start is `cd api && npm start`, health check `/v1/health`.
Production instance: `https://arth-neo.onrender.com`. Point the app at it with
`--dart-define=ARTH_API_URL=https://arth-neo.onrender.com`
or **You → API server** in the app.

## Conventions

- Secrets only in `.env`; `.env.example` is checked in. The app never holds the OpenAI key.
- Every LLM call goes through one `LLMProvider` interface; model names live in config.
- Conventional commits, one scope per phase.
- API: TypeScript strict, Zod on every route, one structured log line per request.

## Attribution

Dictionary data derives from the English Wiktionary via [kaikki.org](https://kaikki.org),
licensed CC BY-SA. Headword frequencies from [`wordfreq`](https://github.com/rspeer/wordfreq) (MIT).
