# Braille style sheet for United States and Canada (BANA)

This style sheet implements the formatting rules of the [Braille Authority of North America (BANA)](https://www.brailleauthority.org/). [UEB](https://iceb.org/) is used as the braille code for all text.

For input formats:

- HTML
- DTBook

For output formats:

- ✅ print braille
- ❌ eBraille

URL of latest stable version: [`https://raw.githubusercontent.com/daisy/braille-stylesheets/refs/heads/main/bana/bana.scss`](https://raw.githubusercontent.com/daisy/braille-stylesheets/refs/heads/main/bana/bana.scss)

[Source code](https://github.com/daisy/braille-stylesheets/blob/main/bana/bana.scss)

## How to use

The style sheet works out of the box, but has a few options to make it behave better for your specific case:

### Running header

A running header can be rendered on the first line of each page (except frontmatter pages), but for this to happen the running header text must be set explicitly. This is done using the [`string-set` property](https://braillespecs.github.io/braille-css/#h4_the-string-set-property).

Example:

```css
head > title {
    string-set: running-header content();
}
```

### Transcriber generated pages

Transcriber generated content can be placed at the beginning of each volume, before the table of contents. For this to happen it must be marked explicitly, using the [`-daisy-flow` property](https://braillespecs.github.io/braille-css/#h4_the-flow-property). In order for it to get the correct page layout, a [`page` property](https://braillespecs.github.io/braille-css/#the-page-property) must also be set.

Example:

```css
section.title-page {
    -daisy-flow: transcriber-generated;
    page: transcriber-generated;
}
```

Note that, except for the table of contents, no content is actually generated automatically. The title page, list of special symbols, etc. must be present in the source document.

### Other preliminary content

Other preliminary content at the beginning of the first volume can be given the correct page layout (with p-prefixed page numbers) using the [`page` property](https://braillespecs.github.io/braille-css/#the-page-property). If it needs to be moved after the transcriber generated content and table of contents, i.e. if it is not in the correct order in the source, a [`-daisy-flow` property](https://braillespecs.github.io/braille-css/#h4_the-flow-property) is required as well.

Example:

```css
section.introduction {
    page: preliminary;
}
```

### Heading styles

By default, `h1` elements are centered, `h2` elements are cell-5 headings, and elements `h3` to `h6` are cell-7 headings. This mapping may be changed, using the Sass variable `$h-mapping`.

**Important**: set the variable _after_ importing bana.scss to override the default.

Example:

```scss
@import "bana";
$h-mapping: (
    h1: [ h1, h2, h3 ],
    h2: h4,
    h3: [h5, h6]
);
```
