do_figs = T
do_tbls = T

librarian::shelf(
  DBI, dplyr, fs, gt, here, knitr, leaflet, purrr, readr, sf, terra,
  offshorewindhabitat/offhabr)
# devtools::load_all(here::here("../offhabr"))
# devtools::install_github("offshorewindhabitat/offhabr", force = T)
terraOptions(progress=0)

# paths ----
species_all_treemap_png <- here("figures/species_all_treemap.png")
species_all_table_png   <- here("figures/species_all_table.png")

# database ----
con <- oh_con() # dbDisconnect(con, shutdown = T)
# dbListTables(con)

# common variables ----
if (!exists("d_ds")){
  d_ds <- tbl(con, "datasets") |>
    filter(
      active,
      ds_key != "oh") |>
    collect()

  d_lyrs_ds <- tbl(con, "lyrs") |>
    filter(
      !is.na(aphia_id),
      is_ds_prime,
      ds_key != "oh") |>
    group_by(ds_key) |>
    summarize(n_lyr = n()) |>
    left_join(
      tbl(con, "lyr_rgn_ds") |>
        left_join(
          tbl(con, "datasets") |>
            select(ds_key, ds_id),
          by = "ds_id") |>
        group_by(ds_key) |>
        summarize(n_rgn = n()),
      by = "ds_key") |>
    arrange(ds_key) |>
    collect() |>
    # replace_na(list(n_rgn = 0)) |>
    mutate(
      n_lyr_rgn = purrr::map2_int(n_lyr, n_rgn, sum, na.rm=T))

  d_ds <- d_ds |>
    left_join(
      d_lyrs_ds,
      by = "ds_key")

  nspp_density <- d_ds |>
    filter(type == "density") |>
    summarize(
      n_taxa = sum(n_lyr_rgn)) |>
    pull(n_taxa)
  nspp_probability <- d_ds |>
    filter(type == "probability") |>
    summarize(
      n_taxa = sum(n_lyr_rgn)) |>
    pull(n_taxa)
  nspp_range <- d_ds |>
    filter(type == "range") |>
    summarize(
      n_taxa = sum(n_lyr_rgn)) |>
    pull(n_taxa)

  nspp <- tbl(con, "lyrs") |>
    filter(!is.na(aphia_id), is_ds_prime) |>
    summarize(n = n()) |>
    pull(n)

  r_depth <- rast(
    system.file("oh_elev_m.tif", package="offhabr"))
  r_depth_web <- rast(
    system.file("oh_elev_m_web.tif", package="offhabr"))

  r_areakm2 <- cellSize(r_depth, unit="km") |>
    mask(r_depth)
  rng_areakm2 <- global(r_areakm2, "range", na.rm=T)
  #            min       max
  # area 0.1022107 0.1927433
  r_web_areakm2 <- cellSize(r_depth_web, unit="km") |>
    mask(r_depth_web)
  rng_web_areakm2 <- global(r_web_areakm2, "range", na.rm=T)
  #            min       max
  # area 0.1642863 0.3114606

}

# functions ----

get_d_spp <- function(){
  d_spp <- tbl(con, "lyrs") |>
    filter(
      !is.na(aphia_id),
      is_ds_prime) |>
    select(aphia_id) |>
    left_join(
      tbl(con, "taxa_wm") |>
        select(
          aphia_id, kingdom, phylum, class,
          # TODO: add vernacular back
          # order, family, genus, scientificname, vernacular),
          order, family, genus, scientificname),
      by = "aphia_id") |>
    #select(-aphia_id) |>
    mutate(
      vernacular = NA, # TODO: add vernacular back
      n = 1) |>
    arrange(
      kingdom, phylum, class,
      order, family, genus, scientificname) |>
    collect()
  # check no duplicates and has all info
  stopifnot(
    sum(duplicated(d_spp$scientificname)) == 0,
    sum(is.na(d_spp$kingdom))       == 0)
  d_spp
}

widget_webshot <- function(w, img, redo=F, delete_html=T,...){
  if (!file.exists(img) | redo){
    h <- path_ext_set(img, ".html")
    h_dir <- glue("{path_ext_remove(img)}_files")
    saveWidget(w, h)
    webshot(h, img, ...)
    if (delete_html){
      dir_delete(h_dir)
      file_delete(h)
    }
  }
  w
}
