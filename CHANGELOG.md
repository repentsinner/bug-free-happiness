# [0.7.0](https://github.com/repentsinner/bug-free-happiness/compare/v0.6.0...v0.7.0) (2026-11-15)


### Features

* **python:** deprecate mypy in favour of pyright, with a warning ([e9def52](https://github.com/repentsinner/bug-free-happiness/commit/e9def52946df478e48a4386a061c3f6bca51af9b))
* **python:** require a type checker and warn when a caller disables it ([15d49bb](https://github.com/repentsinner/bug-free-happiness/commit/15d49bbe713d1d3ab68b08fa6fc119210ce8197a))

# [0.6.0](https://github.com/repentsinner/bug-free-happiness/compare/v0.5.0...v0.6.0) (2026-11-15)


### Features

* **security:** check each pin's comment against the tags at its commit ([0a82ff6](https://github.com/repentsinner/bug-free-happiness/commit/0a82ff668728ba6abb5ef02d683dd8e8461e109f))
* **security:** check that every Action is pinned by SHA with its release ([33c87d5](https://github.com/repentsinner/bug-free-happiness/commit/33c87d571c77c5137a26cfe75fa3c72dc54f25d0))

# [0.5.0](https://github.com/repentsinner/bug-free-happiness/compare/v0.4.0...v0.5.0) (2026-11-15)


### Features

* **python:** fetch private git dependencies with an App token ([3abdd68](https://github.com/repentsinner/bug-free-happiness/commit/3abdd6885fac03db5b528af7f71a19a2286afb41))

# [0.4.0](https://github.com/repentsinner/bug-free-happiness/compare/v0.3.1...v0.4.0) (2026-11-15)


### Features

* **python:** publish the Python correctness workflow ([4ed06c8](https://github.com/repentsinner/bug-free-happiness/commit/4ed06c8879ee0c00f8e6d25e198e869da7688a1e))
* **python:** read the lint-tool pins from a uv project Dependabot bumps ([025602f](https://github.com/repentsinner/bug-free-happiness/commit/025602f57fd33fc1bda51978b5f8e9f1ab4f11a4))

## [0.3.1](https://github.com/repentsinner/bug-free-happiness/compare/v0.3.0...v0.3.1) (2026-11-15)


### Bug Fixes

* **rulesets:** set the review dismissal restriction explicitly ([#36](https://github.com/repentsinner/bug-free-happiness/issues/36)) ([de19866](https://github.com/repentsinner/bug-free-happiness/commit/de19866dcff1f7400a785a5d29b478d83d7edccb))

# [0.3.0](https://github.com/repentsinner/bug-free-happiness/compare/v0.2.2...v0.3.0) (2026-11-15)


### Features

* **security:** check the Dependabot configuration under quality / security ([cd41d9e](https://github.com/repentsinner/bug-free-happiness/commit/cd41d9e575c55c6c3ceaa590ad0ddf6afb68e79c))

## [0.2.2](https://github.com/repentsinner/bug-free-happiness/compare/v0.2.1...v0.2.2) (2026-09-18)


### Bug Fixes

* **flywheel-pr:** keep a skipping run from cancelling the run that posts the check ([#31](https://github.com/repentsinner/bug-free-happiness/issues/31)) ([421e9e7](https://github.com/repentsinner/bug-free-happiness/commit/421e9e70086f4d96468452c73310208bd150c94b))

## [0.2.1](https://github.com/repentsinner/bug-free-happiness/compare/v0.2.0...v0.2.1) (2026-09-16)


### Bug Fixes

* **changelog:** drop the release-please title buried under the first Flywheel release ([#26](https://github.com/repentsinner/bug-free-happiness/issues/26)) ([daeb3a2](https://github.com/repentsinner/bug-free-happiness/commit/daeb3a292f6a28def08f63fae67292baac77d59f))

# [0.2.0](https://github.com/repentsinner/bug-free-happiness/compare/v0.1.3...v0.2.0) (2026-09-16)


### Bug Fixes

* **ci:** quote the auto-merge condition so the workflow parses ([fb7b785](https://github.com/repentsinner/bug-free-happiness/commit/fb7b78575e8f26ca784c647c5a17bbd16c3f95fc))


### Features

* **rulesets:** publish the ruleset template ([91c1445](https://github.com/repentsinner/bug-free-happiness/commit/91c144530a1480f5536c51db8b0ed796f82548be))

## [0.1.3](https://github.com/repentsinner/bug-free-happiness/compare/v0.1.2...v0.1.3) (2026-02-27)


### Bug Fixes

* **ci:** accept bare "complete" in SPEC.md status lines ([f0bb1b1](https://github.com/repentsinner/bug-free-happiness/commit/f0bb1b1421f8337ae7afca25aba48215212a1a08))
* **ci:** enforce exact status line values in SPEC.md ([928d1dd](https://github.com/repentsinner/bug-free-happiness/commit/928d1dd93f23bb18ebfedd743121549440f0df92))

## [0.1.2](https://github.com/repentsinner/bug-free-happiness/compare/v0.1.1...v0.1.2) (2026-02-27)


### Bug Fixes

* **ci:** lint only governance files in docs-lint ([9856d08](https://github.com/repentsinner/bug-free-happiness/commit/9856d08dcbf538bb097971129bdd405f0735e631))
* **ci:** lint only governance files in docs-lint ([94488f8](https://github.com/repentsinner/bug-free-happiness/commit/94488f8910abe71a00fd23115323c78309958210))

## [0.1.1](https://github.com/repentsinner/bug-free-happiness/compare/v0.1.0...v0.1.1) (2026-02-27)


### Features

* **ci:** add opt-in README heading validator ([d7e41c0](https://github.com/repentsinner/bug-free-happiness/commit/d7e41c0ba4dd5707a0d871af4a2449ba2d38a480))
* **ci:** add opt-in README heading validator ([e3bd1c1](https://github.com/repentsinner/bug-free-happiness/commit/e3bd1c129680d847a2e68cc28ede4951e98bba60))
* **ci:** add reusable spec-lint workflow ([e95e7c1](https://github.com/repentsinner/bug-free-happiness/commit/e95e7c168d4be175dc035aef17727d037d65f828))


### Bug Fixes

* **ci:** revert to RELEASE_PLEASE_PAT for workflow chain triggers ([6bc0682](https://github.com/repentsinner/bug-free-happiness/commit/6bc06821a8b42fed79a98fc081f58cc022236855))
* **ci:** use GITHUB_TOKEN instead of PAT for public repo ([c1017ac](https://github.com/repentsinner/bug-free-happiness/commit/c1017ac040eea6ccc83f6cfab9e1cf05ef220ac0))
* **config:** disable MD036 for italic status lines ([caf621e](https://github.com/repentsinner/bug-free-happiness/commit/caf621e5eff329f8a0814dc8e8ead9d6e74e4c22))
* **docs:** move status lines immediately after section headings ([ec42f0e](https://github.com/repentsinner/bug-free-happiness/commit/ec42f0e1f6dd6b15cf77f80311907dd05d891dd2))
* **docs:** move status lines immediately after section headings ([c1d4317](https://github.com/repentsinner/bug-free-happiness/commit/c1d431725e55c5e2cc4581ae6615f6facf067e5a))
