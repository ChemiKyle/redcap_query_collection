library(tidyverse)
library(rvest)

url <-  read_html("https://redcap.vanderbilt.edu/consortium/modules/index.php")
# located at bottom of page - "Showing 1 to n of y entries" where y is number_of_entries
number_of_entries <- 128

get_private_git_repos <- function(){

  private_git_repo <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(',entry, ') > td:nth-child(1) > div:nth-child(1)')) %>%
    html_text() %>%
    str_detect(., "Private repository")

  tibble(entry = entry, private_git_repo = private_git_repo)

}

private_git_repos <- list()
for (entry in c(1:number_of_entries)){
  private_git_repos[[entry]] <- get_private_git_repos()

}

private_git_repos <- bind_rows(!!!private_git_repos) %>%
  filter(private_git_repo)

scrape_redcap_repo <- function(entry){
  title <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(1) > span')) %>%
    html_text()

  deployed <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(1) > i')) %>%
    html_text()

  github_url <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(1) > a')) %>%
    html_attr("href")

  description <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(2)')) %>%
    html_text()

  date_added <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td.text-center.nowrap')) %>%
    html_text()

  downloads <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(3)')) %>%
    html_text()

  author <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(3) > a')) %>%
    html_text()

  author_email <- url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(3) > a')) %>%
    html_attr("href")

  institution <-  url %>%
    html_nodes(str_c('#modules-table > tbody > tr:nth-child(', entry, ') > td:nth-child(1) > div:nth-child(3) > span')) %>%
    html_text()

  tibble(title = title, deployed = deployed, github_url = github_url,
         description = description, date_added = date_added, downloads = downloads,
         author = author, author_email = author_email, institution = institution)
}

# exclude any private github repos
redcap_repo_entries <- (1:number_of_entries)[-private_git_repos$entry]

redcap_repo_data <- list()
for (entry in redcap_repo_entries){
  redcap_repo_data[[entry]] <- scrape_redcap_repo(entry)
}

redcap_repo_data <- bind_rows(!!!redcap_repo_data) %>%
  mutate_at(vars(c("deployed", "institution")), ~ str_remove_all(., "\\(|\\)")) %>%
  mutate_at(vars(c("description", "author_email")), ~ str_remove_all(., "Description: |mailto:")) %>%
  mutate(version = str_extract(deployed, "v\\d.+"),
         deployed = str_remove(deployed, "_v\\d.+")) %>%
  select(title, deployed, version, everything())

write.csv(redcap_repo_data, "redcap_repo_data.csv", row.names = F, na = "")

