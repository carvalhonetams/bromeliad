#' Mapping Bromeliad Species Richness
#'
#' Produces a richness map in a 100x100 km grid for the selected bromeliaceae species.
#'
#' @param x an object of the class \dQuote{bromeli} generated by get_range.
#' @param title An optional title to be added to the plot.
#'
#' @return aa richness map of the selected taxa across the Neotropics.
#' .
#' @examples
#' map_richness(x = get_range(genus = "Aechmea", type = "binary"))
#'
#' @export
#' @importFrom rnaturalearth ne_download
#' @importFrom speciesgeocodeR RangeRichness
#' @importFrom sp spTransform CRS
#' @importFrom sf st_transform
#' @importFrom ggplot2 aes annotate fortify ggtitle coord_fixed fortify geom_polygon geom_sf geom_tile ggplot theme xlim ylim
#' @importFrom ggthemes theme_map
#' @importFrom viridis scale_fill_viridis
#' @importFrom raster crop extend extent raster rasterToPoints



map_richness <- function(x, title = NULL){

  if(!"bromeli" %in% class(x)){
      stop("x must be of class bromeli, generated by 'get_range'")
  }else{
    class(x) <- class(x)[!class(x) == "bromeli"]
  }
  # Projection
  wgs1984 <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  behr <- '+proj=cea +lon_0=0 +lat_ts=30 +x_0=0 +y_0=0 +datum=WGS84 +ellps=WGS84 +units=m +no_defs'

  if("sf" %in% class(x)){
    dat <- sf::st_transform(x, behr)

    ## transfom to sp
    dat <- as(dat, 'Spatial')

    # create dummy raster
    be <- raster::raster(ncol = 360, nrow = 142, xmn = -17367529, xmx = 17367529, ymn = -6356742,
                 ymx = 7348382, crs = behr)
    be <- raster::crop(be, raster::extent(dat))

    # get richness raster
    ri <- speciesgeocodeR::RangeRichness(dat, ras = be)
  }else{
    # standardize extent
    be <- raster::raster(ncol = 360, nrow = 142, xmn = -17367529, xmx = 17367529, ymn = -6356742,
                 ymx = 7348382, crs = behr)
    e <- raster::extent(be)
    re <-  lapply(x, function(r){raster::extend(r,e)})

    out <-  list()
    re <- for(i in 1:length(re)){
      sub <- re[[i]]
      sub[is.na(sub)] <- 0
      out[[i]] <-  sub
      }

    # get richness raster
    ri <- Reduce("+", out)
  }


  #Background map
  world.inp  <- rnaturalearth::ne_download(scale = 110,
                                           type = 'countries',
                                           load = TRUE)

  world.behr <- sp::spTransform(world.inp, sp::CRS(behr)) %>% ggplot2::fortify()

  #convert to ggplot2 format
  ri <- data.frame(raster::rasterToPoints(ri))%>%
    mutate(layer = ifelse(.data$layer == 0, NA, .data$layer))

  # Plot
  if(sum(ri$layer,na.rm = TRUE) > 0){
    plo_tot <- ggplot()+
      ggplot2::geom_tile(data = ri, aes(x = .data$x, y = .data$y, fill = .data$layer), alpha = 1)+
      viridis::scale_fill_viridis(name = "Species", direction = -1, na.value = "transparent")+
      geom_polygon(data = world.behr,
                   aes(x = .data$long, y = .data$lat, group = .data$group), fill = "transparent", color = "black")+
      ggplot2::xlim(-12000000, -3000000)+
      ggplot2::ylim(-6500000, 4500000)+
      ggplot2::coord_fixed()+
      ggthemes::theme_map()+
      ggplot2::theme(legend.justification = c(0, 0),
                     legend.position = c(0, 0))
  }else{
    plo_tot <- ggplot()+
      ggplot2::geom_tile(data = ri, aes(x = .data$x, y = .data$y), alpha = 1)+
     # viridis::scale_fill_viridis(name = "Species", direction = -1, na.value = "transparent")+
      geom_polygon(data = world.behr,
                   aes(x = .data$long, y = .data$lat, group = .data$group), fill = "transparent", color = "black")+
      ggplot2::xlim(-12000000, -3000000)+
      ggplot2::ylim(-6500000, 4500000)+
      ggplot2::coord_fixed()+
      ggthemes::theme_map()+
      ggplot2::theme(legend.justification = c(0, 0),
                     legend.position = c(0, 0))
  }


  if(!is.null(title)){
    plo_tot <- plo_tot+
      ggtitle(title)
  }

  plo_tot
}
