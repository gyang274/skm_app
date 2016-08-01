# server.R

shinyServer(function(input, output, session) {
  
  #- init state
  values <- reactiveValues(init = TRUE)
  
  # session$onFlushed(once = FALSE, function() {
  #   
  # })
  
  #- observe user selection
  updateSelectInput(session, "obj")
  
  observe({
    updateSelectInput(session, "oms", selected = input$obj)
  })
  
  #- observe action button clicks  
  observe({

    if ( (input$fnd > 0) || (input$ovw > 0) ) { values$init <- FALSE }

  })
  
  #- observe user interaction - map id clicks
  observe({
  
    #- observe map id clicks
    ## 1. show message on message board
    ## 2. TODO add clicked into prefixed warehouse location?  
    click <- input$map_marker_click
    
    if ( is.null(click) ) { return() }
    
    output$msgs <- renderText({
      
      paste("You've selected ", click$id, " - Add it into Prefixed locations?")
      
    })
    
  })
  
  #- analytic view
  create_optimal_wlist <- eventReactive(input$fnd, {
    
    output$msgs <- renderText({
      paste0(
        "You've selected to find ", input$kwh, " warehouse locations ", 
        "in objective to minimize ", input$wgt, " weighed average ", input$obj, " ",
        "with ", length(input$pfx), " pre-selected locations: ",
        paste(input$pfx, collapse = ", "), ".")
    })
    
    ## map input variable to analytical variable name
    m_obj <- (input$obj %|% dobj[["nam"]][1]) %>% map_obj_v
    
    m_wgt <- (input$wgt %|% dwgt[["nam"]][1]) %>% map_wgt_v
    
    m_pfx <- (input$pfx %|% integer(0L)) %>% map_dsrc_s %>% unlist 
    
    ## create and load analytical data and parameters
    
    s_must_idx_cpp <- integer(0L)
    
    if( length(m_pfx) > 0 ) {
      
      s_must_idx_cpp <- match(m_pfx, dsrc[["s"]]) - 1
      
    }
    
    ## optimization
    
    # output$msgs <- renderText({ "create_optimal_wlist: analysis is running ...\n" })
    
    eval(parse(
      text = 'a_skmSolution <- skm_mls_cpp(dmtx' %+% '_' %+% m_obj %+% '_' %+% m_wgt %+% ', ' %+% 
        'k = input$kwh, g = dsrc[["g"]], s_must = s_must_idx_cpp, max_it = 100L, max_at = input$nas)'
    ))
    
    # output$msgs <- renderText({ "create_optimal_wlist: analysis is complete ...\n" })
    
    # output$msgs <- renderText({
    #   paste0(
    #     "You've selected to find ", input$kwh, " warehouse locations ",
    #     "in objective to minimize ", input$wgt, " weighed average ", input$obj, " ",
    #     "with ", length(input$pfx), " pre-selected locations: ",
    #     paste(input$pfx, collapse = ", "), ".")
    # })
    
    return(a_skmSolution)
    
  })
  
  view_optimal_wlist <- eventReactive(input$fnd | input$ovw, {
    
    a_skmSolution <- create_optimal_wlist()
    
    ## optimality rank w.r.t objective
    optim_rank_idx = sort(a_skmSolution$o_list, index.return = TRUE)$ix
    
    ## create tbl w.r.t objective optimal rank otk
    o_otk <- a_skmSolution$o_list[optim_rank_idx[input$otk]]
    
    ## all(dlst[["s_name"]] == dsrc[["s"]]) is TRUE
    s_otk_idx <- a_skmSolution$s_list[optim_rank_idx[input$otk], ] + 1L
    
    s_otk <- dsrc[s_otk_idx, id] %>% paste(collapse = ",\n")
    
    optim_tbk <- data.table(
      Metric = c("Rank", "Objective", "Location"),
      Values = c(input$otk, round(o_otk, 2L), s_otk)
    )
    
    ## create map w.r.t objective optimal rank otk
    optim_map_s <- dsrc[s_otk_idx, ]
    
    m_oms <- ifelse(grepl("(dist|zone)", input$oms), "zone", "stnt")
    
    m_wgt <- (input$wgt %|% dwgt[["nam"]][1L]) %>% map_wgt_v
    
    st_sidx <- dmtx_map_dist[s_otk_idx, , drop = FALSE] %>% apply(2L, which.min)

    st_tidx <- c(1L:length(st_sidx))
    
    st_midx <- cbind(st_sidx, st_tidx)
    
    eval(parse(
      text = paste0(
        'optim_map_t <- cbind(ddst[subset_t_indx , .(t, t_lat, t_lng)], vms = dmtx_map_', 
        m_oms, '[s_otk_idx, ][st_midx]) %>% mutate(rgbc = map_', m_oms, '_c(vms))')
    ))
    
    return(list(map_s = optim_map_s, map_t = optim_map_t, tbk = optim_tbk))
    
  })

  output$map <- renderLeaflet({
    
    if ( values$init ) {
    
      map <- leaflet() %>%
        addProviderTiles(
          "Stamen.TonerLite", 
          options = providerTileOptions(noWrap = TRUE)
        ) %>%
        addCircleMarkers(
          lat = dsrc[["s_lat"]],
          lng = dsrc[["s_lng"]],
          layerId = dsrc[["id"]],
          popup = dsrc[["popup"]],
          radius = 10L,
          color = "#99cc00",
          stroke = FALSE, 
          fillOpacity = 0.50
        )
      
      return( map )
      
    }
    
    optim_list <- view_optimal_wlist()
    
    optim_map_s = optim_list[["map_s"]]
    
    optim_map_t = optim_list[["map_t"]]
    
    map <- leaflet() %>%
      addProviderTiles(
        "Stamen.TonerLite", 
        options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addMarkers(
        lat = optim_map_s[["s_lat"]],
        lng = optim_map_s[["s_lng"]],
        layerId = optim_map_s[["id"]],
        # icon = metroIcons,
        popup = optim_map_s[["popup"]]
      ) %>%
      addCircleMarkers(
        lat = optim_map_t[["t_lat"]],
        lng = optim_map_t[["t_lng"]],
        layerId = optim_map_t[["t"]],
        radius = 4L,
        color = optim_map_t[["rgbc"]],
        stroke = FALSE, 
        fillOpacity = 0.50
      )
    
    return( map )
    
  })
  
  output$tbk <- renderDataTable({
    
    optim_list <- view_optimal_wlist()
    
    tbk <- optim_list[["tbk"]] %>%
      DT::datatable(
        options = list(
          dom = 't',
          pageLength = 10L,
          lengthMenu = "",
          initComplete = JS(
            "function(settings, json) {
              $(this.api().table().header()).css({'background-color': '#ffe0b3', 'color': '#000000'});
              $(this.api().table().body()  ).css({'background-color': '#cceeff', 'color': '#000000'});
            }")),
          rownames = FALSE,
          escape = FALSE)
    
    return(tbk)
    
  })
  
  output$cpan_tb <- renderDataTable({
    
    if ( grepl("(dist|zone)", input$oms)  ) {
      
      cpan_tb <- data.table(
        Distance = map_dist_zone_list[["dist"]],
        Zone = map_dist_zone_list[["zone"]]
      ) %>%
        DT::datatable(
          options = list(
            dom = 't',
            pageLength = 10L,
            lengthMenu = "",
            initComplete = JS(
              "function(settings, json) {
                $(this.api().table().header()).css({'background-color': '#ffe0b3', 'color': '#000000'});
                $(this.api().table().body()  ).css({'background-color': '#cceeff', 'color': '#000000'});
              }")),
          rownames = FALSE,
          escape = FALSE) %>%
        formatStyle(
          "Zone", backgroundColor = styleEqual(map_dist_zone_list[["zone"]], map_dist_zone_list[["rgbc"]])
        ) %>%
        formatStyle(
          "Distance", backgroundColor = styleEqual(map_dist_zone_list[["dist"]], map_dist_zone_list[["rgbc"]])
        )
      
    } else {
      
      cpan_tb <- data.table("Time in Transit" = c(1L:6L)) %>%
        DT::datatable(
          options = list(
            dom = 't',
            pageLength = 20L,
            lengthMenu = "",
            initComplete = JS(
              "function(settings, json) {
                $(this.api().table().header()).css({'background-color': '#ffe0b3', 'color': '#000000'});
                $(this.api().table().body()  ).css({'background-color': '#cceeff', 'color': '#000000'});
              }")),
            rownames = FALSE,
          escape = FALSE) %>%
        formatStyle(
          "Time in Transit", backgroundColor = styleEqual(map_stnt_list[["stnt"]], map_stnt_list[["rgbc"]])
        )
    }
      
    return( cpan_tb )
      
  })
  
  #- data explorer
  output$pdeDEV <- renderDataTable({
    
    pdeDEV <- ddst
    
    if ( length(input$pdeStt) > 0L ) {
      
      pdeDEV <- pdeDEV %>%
        subset(state %in% input$pdeStt)
     
      if ( length(input$pdeCit) > 0L ) {
        
        pdeDEV <- pdeDEV %>%
          subset(city %in% input$pdeCit)
        
      }
      
    }
    
    pdeDEV <- pdeDEV %>%
      setcolorder(
        c("state", "city", "t", "t_lat", "t_lng", 
          "pop", "ink", "p_pop", "p_ink")
      ) %>%
      DT::datatable(
        options = list(
          pageLength = 10L,
          lengthMenu = "",
          initComplete = JS(
            "function(settings, json) {
              $(this.api().table().header()).css({'background-color': '#ffe0b3', 'color': '#000000'});
              $(this.api().table().body()  ).css({'background-color': '#cceeff', 'color': '#000000'});
          }")),
      rownames = FALSE,
      colnames = c(
        "State" = "state",
        "City" = "city",
        "ZIP" = "t",
        "Latitude" = "t_lat",
        "Longitude" = "t_lng",
        "Population" = "pop",
        "Total Income" = "ink",
        "% Population" = "p_pop",
        "% Total Income" = "p_ink"
      ),
      escape = FALSE) %>%
      formatCurrency("Total Income") %>%
      formatCurrency("Population", currency = "", interval = 3L, mark = ",") %>%
      formatPercentage(c("% Population", "% Total Income"), digits = 6L)
    
  })
  
})