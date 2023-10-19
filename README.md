# offhab-report
online report components as quarto book

- [password protect GH Pages](https://github.com/chrissy-dev/protected-github-pages)

## Quarto rendering


### Cache invalidation

[Quarto - Managing Execution](https://quarto.org/docs/projects/code-execution.html#cache)

```bash
quarto render methods.qmd --cache-refresh --to html  # single doc
quarto render methods.qmd --cache-refresh --to docx  # single doc
quarto render --cache-refresh --to docx              # entire project
```
      
