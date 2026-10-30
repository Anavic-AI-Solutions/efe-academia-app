library phosphor_flutter;

// NOTE (EFE patch): phosphor_flutter 2.1.0 declared
// `class PhosphorIconData extends IconData`, which no longer compiles since
// Flutter 3.43 made IconData final. Every icon constant in this vendored copy
// was rewritten to a plain const IconData(...) with identical code point,
// font family, package and mirroring behavior. This file is kept (empty) so
// existing imports keep resolving. Duotone icons resolve to their primary
// glyph; the secondary overlay layer is not available.
