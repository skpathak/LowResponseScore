library(dplyr)
library(sf)

allegheny_blockgroups_muncipals <- readRDS("data/borough_data.rds")
borough_names <- readRDS("data/borough_names.rds")
pdb.var.names <- readRDS("data/pdb_var_names.rds")

allegheny_blockgroups_muncipals <- st_transform(allegheny_blockgroups_muncipals, "+init=epsg:4326")

cleantable <- allegheny_blockgroups_muncipals %>% 
        st_set_geometry(NULL) %>% 
        select_(.dots = c(Municipality = "Municipality", pdb.var.names)) #, lat = "INTPTLAT", lng = "INTPTLON", geoid = "GEOID"))