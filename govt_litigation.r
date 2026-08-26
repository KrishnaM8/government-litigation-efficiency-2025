library(readr)
library(stringr)
library(dplyr)

main_lsd_data <- read.csv("hearingsandmatters_data2.csv")

#Keyword lists to identify government, private, and ambiguous entities
strong_govt_keywords <- c("UNION OF INDIA", "STATE OF", "GOVT", "GOVERNMENT",
                          "DEPARTMENT", "MINISTRY", "POLICE", "RTO",
                          "MUNICIPAL", "NAGAR", "PANCHAYAT",
                          "COLLECTOR", "SEBI", "RBI", "CBI", "INCOME TAX",
                          "ELECTION COMMISSION", "FOREST", "RESERVE BANK",
                          "REGISTRAR", "BOMBAY", "MAHARASHTRA",
                          "MAGISTRATE", "COUNCIL", "SECRETARY", "ADMINISTRAT")

ambiguous_keywords <- c("CORPORATION", "BOARD", "AUTHORITY", "COMMISSION",
                        "NATIONAL", "INDIA", "TRUST", "TAX", "COMMITTEE",
                        "SERVICE")

private_keywords <- c("PVT", "PRIVATE", "LLP", "INC", "PLC")

#Context words used to disambiguate entities that could belong to govt
govt_context_keywords <- c("OF INDIA", "STATE", "GOVT", "GOVERNMENT",
                           "MINISTRY", "DEPARTMENT", "PUBLIC", "MUNICIPAL",
                           "NAGAR", "URBAN", "PANCHAYAT", "REGULATORY",
                           "BUREAU", "CENTRAL", "DISTRICT", "ZILLA",
                           "BOARD OF", "DEVELOPMENT AUTHORITY", "COMMISSIONER",
                           "ELECTION", "COUNCIL", "SOCIETY")

#Classifying whether a given name likely represents a government entity
is_govt <- function(name) {
  name_upper <- toupper(name)
  if (any(str_detect(name_upper, str_c(private_keywords, collapse = "|")))) {
    return(0)
  }
  if (any(str_detect(name_upper,
                     str_c(strong_govt_keywords, collapse = "|")))) {
    return(1)
  }
  if (any(str_detect(name_upper, str_c(ambiguous_keywords, collapse = "|"))) &&
        any(str_detect(name_upper,
                       str_c(govt_context_keywords, collapse = "|")))) {
    return(1)
  }
  return
}

#Classification function to both petitioner and respondent names
main_lsd_data2 <- main_lsd_data %>%
  mutate(
    petitioner_is_govt = sapply(petitioners, is_govt),
    respondent_is_govt = sapply(respondents, is_govt),
    govt_case_or_not = ifelse(
      petitioner_is_govt == 0 & respondent_is_govt == 0, 0, 1
    )
  )

# Separate cases into govt-involved and purely private
govt_cases <- main_lsd_data2 %>%
  filter(petitioner_is_govt == 1 | respondent_is_govt == 1)

non_govt_cases <- main_lsd_data2 %>%
  filter(petitioner_is_govt == 0 & respondent_is_govt == 0)

#Finding time to disposal and survival
library(survival)
library(survminer)

main_lsd_data2 <- main_lsd_data2 %>%
  mutate(
    filing_date = as.Date(filing_date, format = "%Y-%m-%d"),
    disposal_date = as.Date(disposal_date, format = "%Y-%m-%d"),
    updated_on = as.Date(updated_on, format = "%Y-%m-%d")
  )