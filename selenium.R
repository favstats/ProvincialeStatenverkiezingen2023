
library(RSelenium)

# https://adstransparency.google.com/advertiser/AR09355418985304162305?political&region=NL&preset-date=Last%207%20days


library(netstat)
library(RSelenium)
# port <- netstat::free_port()
podf <- sample(4000L:5000L,1)
rD <- rsDriver(browser = "firefox"
                    ,chromever=NULL
                ,check = F
                ,port = podf
                ,verbose = T
)


library(rvest)

remDr <- rD$client


# ggl_spend

retrieve_spend <- function(id, days = 30) {

    # id <- "AR18091944865565769729"
    url <- glue::glue("https://adstransparency.google.com/advertiser/{id}?political&region=NL&preset-date=Last%20{days}%20days")
    remDr$navigate(url)

    Sys.sleep(1)

    thth <- remDr$getPageSource() %>% .[[1]] %>% read_html()

    Sys.sleep(3)
    
    root5 <- "/html/body/div[3]" 
    root3 <- "/html/body/div[5]" 
    ending <- "/root/advertiser-page/political-tabs/div/material-tab-strip/div/tab-button[2]/material-ripple"

    try({
      insights <<- remDr$findElement(value = paste0(root5, ending))
      it_worked <- T
    })
    
    if(!exists("it_worked")){
      
      print("throwed an error")
      
      try({
        insights <<- remDr$findElement(value = paste0(root3, ending))
        
      })
      
      root <- root3
      
    } else {
      root <- root5
    }
    
    print("click now")
    insights$clickElement()

    Sys.sleep(3)

    pp <- remDr$getPageSource() %>% .[[1]] %>% read_html()
    
    ending_eur <- "/root/advertiser-page/insights-grid/div/div/overview/widget/div[3]/div[1]/div"
    ending_ads <- "/root/advertiser-page/insights-grid/div/div/overview/widget/div[3]/div[3]/div"
    
    print("retrieve numbers")
    # try({
    eur_amount <- pp %>%
        html_elements(xpath = paste0(root, ending_eur)) %>%
        html_text()
    
    num_ads <- pp %>%
        html_elements(xpath = paste0(root, ending_ads)) %>%
        html_text()
    
    # })
    
    fin <- tibble(advertiser_id = id, eur_amount, num_ads)
    
    print(fin)

    return(fin)

}

ggl_spend <- readRDS("data/ggl_spend.rds")

# retrieve_spend(unique(ggl_spend$Advertiser_ID)[1])
# fvd <- retrieve_spend("AR03397262231409262593")



ggl_sel_sp <- unique(ggl_spend$Advertiser_ID) %>%
    map_dfr_progress(retrieve_spend)

# ggl_sel_sp %>% 
  # filter(advertiser_id %in% "AR09355418985304162305")
# 
# # ggl_spend %>% 
#   # filter(Advertiser_ID %in% "AR09355418985304162305")
# 
ggl_sel_sp$advertiser_id %>% setdiff(unique(ggl_spend$Advertiser_ID), .)
  # filter(!(advertiser_id %in% unique(ggl_spend$Advertiser_ID)))

# fvd <- retrieve_spend("AR03397262231409262593")
# ggl_sel_sp <- ggl_sel_sp %>%
# bind_rows(fvd) %>%
# distinct(advertiser_id, .keep_all = T)


saveRDS(ggl_sel_sp, file = "data/ggl_sel_sp.rds")

ggl_sel_sp7 <- unique(ggl_spend$Advertiser_ID) %>%
  map_dfr_progress(retrieve_spend, 7)

saveRDS(ggl_sel_sp7, file = "data/ggl_sel_sp7.rds")



retrieve_spend_daily <- function(id, the_date) {

  # id <- "AR18091944865565769729"
  url <- glue::glue("https://adstransparency.google.com/advertiser/{id}?political&region=NL&start-date={the_date}&end-date={the_date}")
  remDr$navigate(url)

  Sys.sleep(1)

  thth <- remDr$getPageSource() %>% .[[1]] %>% read_html()

  Sys.sleep(3)

  root3 <- "/html/body/div[3]"
  root5 <- "/html/body/div[5]"
  ending <- "/root/advertiser-page/political-tabs/div/material-tab-strip/div/tab-button[2]/material-ripple"

  try({
    insights <<- remDr$findElement(value = paste0(root5, ending))
    it_worked <- T
  })

  if(!exists("it_worked")){

    print("throwed an error")

    try({
      insights <<- remDr$findElement(value = paste0(root3, ending))

    })

    root <- root3

  } else {
    root <- root5
  }

  print("click now")
  insights$clickElement()

  Sys.sleep(3)

  pp <- remDr$getPageSource() %>% .[[1]] %>% read_html()

  ending_eur <- "/root/advertiser-page/insights-grid/div/div/overview/widget/div[3]/div[1]/div"
  ending_ads <- "/root/advertiser-page/insights-grid/div/div/overview/widget/div[3]/div[3]/div"

  print("retrieve numbers")
  # try({
  eur_amount <- pp %>%
    html_elements(xpath = paste0(root, ending_eur)) %>%
    html_text()

  num_ads <- pp %>%
    html_elements(xpath = paste0(root, ending_ads)) %>%
    html_text()

  # })

  fin <- tibble(advertiser_id = id, eur_amount, num_ads, date = the_date)

  print(fin)

  return(fin)

}

daily_spending <- readRDS("data/daily_spending.rds")

# 13 February 2023
timelines <- seq.Date(as.Date("2023-02-13"), as.Date("2023-03-15"), by = "day")

# daily_spending <- expand_grid(unique(ggl_spend$Advertiser_ID), timelines) %>%
#   set_names(c("advertiser_id", "timelines")) %>%
#   split(1:nrow(.)) %>%
#   map_dfr(~{retrieve_spend_daily(.x$advertiser_id, .x$timelines)})
# 
# daily_spending <- daily_spending %>%
#   bind_rows(missings) %>%
#   distinct(advertiser_id, date, .keep_all = T)

# saveRDS(daily_spending, file = "data/daily_spending.rds")

# retrieve_spend_daily("AR09355418985304162305", "2023-03-01")

missings <- expand_grid(unique(ggl_spend$Advertiser_ID), timelines) %>%
  set_names(c("advertiser_id", "timelines")) %>%
  anti_join(daily_spending %>% rename(timelines = date))  %>%
  split(1:nrow(.)) %>%
  map_dfr_progress(~{retrieve_spend_daily(.x$advertiser_id, .x$timelines)})

# retrieve_spend_daily("AR18177962546424709121", "2023-03-14")







retrieve_spend_custom <- function(id, from, to) {
  
  # id <- "AR18091944865565769729"
  url <- glue::glue("https://adstransparency.google.com/advertiser/{id}?political&region=NL&start-date={from}&end-date={to}")
  remDr$navigate(url)
  
  Sys.sleep(1)
  
  thth <- remDr$getPageSource() %>% .[[1]] %>% read_html()
  
  Sys.sleep(3)
  
  root3 <- "/html/body/div[3]"
  root5 <- "/html/body/div[5]"
  ending <- "/root/advertiser-page/political-tabs/div/material-tab-strip/div/tab-button[2]/material-ripple"
  
  try({
    insights <<- remDr$findElement(value = paste0(root5, ending))
    it_worked <- T
  })
  
  if(!exists("it_worked")){
    
    print("throwed an error")
    
    try({
      insights <<- remDr$findElement(value = paste0(root3, ending))
      
    })
    
    root <- root3
    
  } else {
    root <- root5
  }
  
  print("click now")
  insights$clickElement()
  
  Sys.sleep(3)
  
  pp <- remDr$getPageSource() %>% .[[1]] %>% read_html()
  
  ending_eur <- "/root/advertiser-page/insights-grid/div/div/overview/widget/div[3]/div[1]/div"
  ending_ads <- "/root/advertiser-page/insights-grid/div/div/overview/widget/div[3]/div[3]/div"
  
  print("retrieve numbers")
  # try({
  eur_amount <- pp %>%
    html_elements(xpath = paste0(root, ending_eur)) %>%
    html_text()
  
  num_ads <- pp %>%
    html_elements(xpath = paste0(root, ending_ads)) %>%
    html_text()
  
  # })
  

  ending_type <- "/root/advertiser-page/insights-grid/div/div/ad-formats/widget/div[4]"
  
  
  type_spend <<- pp %>%
    html_elements(xpath = paste0(root, ending_type)) %>% 
    html_children() %>% 
    html_text() %>% 
    tibble(raww = .) %>% 
    mutate(type = str_to_lower(str_extract(raww, "Video|Text|Image"))) %>% 
    mutate(raww = str_remove_all(raww, "Video|Text|Image") %>% str_remove_all("%|\\(.*\\)") %>% as.numeric) %>% 
    pivot_wider(names_from = type, values_from = raww)
  
  
  fin <- tibble(advertiser_id = id, eur_amount, num_ads, from, to) 
  
  if(nrow(type_spend)!=0){
    fin <- fin %>% 
      bind_cols(type_spend)
  }
  
  
  
  print(fin)
  
  return(fin)
  
}





ggl_sel_sp <- unique(ggl_spend$Advertiser_ID) %>%
  # .[22] %>% 
  map_dfr_progress(~{retrieve_spend_custom(.x, "2023-02-14", "2023-03-15")})

# ggl_sel_sp %>% 
# filter(advertiser_id %in% "AR09355418985304162305")
# 
# # ggl_spend %>% 
#   # filter(Advertiser_ID %in% "AR09355418985304162305")
# 
misssss <- ggl_sel_sp$advertiser_id %>% setdiff(unique(ggl_spend$Advertiser_ID), .)
# filter(!(advertiser_id %in% unique(ggl_spend$Advertiser_ID)))

# ggl_sel_sp <- ggl_sel_sp %>%
# bind_rows(fvd) %>%
# distinct(advertiser_id, .keep_all = T)

# fvd <- retrieve_spend("AR03397262231409262593")
fvd <- retrieve_spend_custom(misssss, "2023-02-14", "2023-03-15")
ggl_sel_sp <- ggl_sel_sp %>%
bind_rows(fvd) %>%
distinct(advertiser_id, .keep_all = T)


saveRDS(ggl_sel_sp, file = "data/ggl_sel_sp.rds")


ggl_sel_sp7 <- unique(ggl_spend$Advertiser_ID) %>%
  # .[22] %>% 
  map_dfr_progress(~{retrieve_spend_custom(.x, "2023-03-09", "2023-03-15")})

misssss7 <- ggl_sel_sp7$advertiser_id %>% setdiff(unique(ggl_spend$Advertiser_ID), .)


saveRDS(ggl_sel_sp7, file = "data/ggl_sel_sp7.rds")


