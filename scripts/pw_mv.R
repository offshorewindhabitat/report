# script to impose password protection after Build
librarian::shelf(
  fs, glue, here)

template_html <- here("scripts/_pw_template.html")
dir_html      <- here("_book")
dir_pw        <- glue("{dir_html}/44ce7cff6e9a3ce81a45412598fcb96fcd5108bc")

# TODO: move dir_html/* -> dir_pw/*
#       cp dir_pw/*.docx -> dir_html/*.docx

for (file_html in list.files(dir_pw, ".*\\.html$")){ # path_dest = dir_ls(dir_pw, glob="*.html")[1]

  file_pw <- glue("{dir_html}/{file_html}")

  # replace {{file_html}} in template into new file for password protection
  readLines(template_html) |>
    glue_collapse(sep = "\n") |>
    glue(.open = "{{", .close = "}}") |>
    writeLines(file_pw)
}


