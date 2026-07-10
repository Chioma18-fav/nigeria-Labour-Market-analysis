library(DBI)
library(RPostgres)
library(dplyr)
library(survey)
library(gt)
library(rlang)
library(webshot2)

options(survey.lonely.psu = "adjust")

# =====================================================
# Connect to PostgreSQL
# =====================================================

con <- dbConnect(
  RPostgres::Postgres(),
  dbname = "nigeria_labour_education_analysis",
  host = "localhost",
  port = 5432,
  user = "postgres",
  password = "Chris2010@ngo"
)

nlfs <- dbReadTable(con, "clean_nlfs")

# =====================================================
# Create Occupation Tier
# =====================================================

nlfs <- nlfs %>%
  mutate(
    occupation_tier = case_when(
      substr(occupation_group,1,1) %in% c("1","2","3") ~ "High Skill",
      substr(occupation_group,1,1) %in% c("4","5","6","7","8") ~ "Medium Skill",
      substr(occupation_group,1,1) == "9" ~ "Low Skill",
      TRUE ~ "Other"
    )
  )

# =====================================================
# Education Categories to Exclude
# =====================================================

excluded_education <- c(
  "OTHER (SPECIFY)",
  "TECH/PROF",
  "MODERN SCHOOL LEAVING CERTIFICATE (MSLC)",
  "VOC/COMM CERTIFICATE",
  "VOC/COMM DIPLOMA",
  "MASTERS",
  "DOCTORATE",
  "ADVANCED (A) LEVEL"
)

quarters <- c("2024q3","2024q4","2025q1","2025q2")

results <- data.frame()

# =====================================================
# LOOP THROUGH EACH QUARTER
# =====================================================

for(q in quarters){
  
  cat("\nRunning tests for", q, "\n")
  
  data_q <- nlfs %>%
    filter(quarter == q)
  
  design_q <- svydesign(
    ids = ~cluster,
    strata = ~stratum,
    weights = ~survey_weight,
    data = data_q,
    nest = TRUE
  )
  
  # =====================================================
  # TEST 1
  # Education vs Occupation Tier
  # =====================================================
  
  design1 <- subset(
    design_q,
    worked_last_7days == "YES" &
      occupation_tier != "Other" &
      !highest_education %in% excluded_education &
      !is.na(highest_education)
  )
  
  test1 <- svychisq(
    ~highest_education + occupation_tier,
    design1,
    statistic = "F"
  )
  
  results <- rbind(
    results,
    data.frame(
      Quarter = q,
      Relationship = "Education vs Occupation Tier",
      F_Statistic = round(as.numeric(test1$statistic),2),
      Numerator_DF = round(test1$parameter[1],2),
      Denominator_DF = round(test1$parameter[2],2),
      P_Value = test1$p.value
    )
  )
  
  # =====================================================
  # TEST 2
  # Education vs Business Registration
  # =====================================================
  
  design2 <- subset(
    design_q,
    employment_type == "In your own business/farming activity" &
      !is.na(formal_job_registration) &
      formal_job_registration != "" &
      !highest_education %in% excluded_education &
      !is.na(highest_education)
  )
  
  test2 <- svychisq(
    ~highest_education + formal_job_registration,
    design2,
    statistic = "F"
  )
  
  results <- rbind(
    results,
    data.frame(
      Quarter = q,
      Relationship = "Education vs Business Registration",
      F_Statistic = round(as.numeric(test2$statistic),2),
      Numerator_DF = round(test2$parameter[1],2),
      Denominator_DF = round(test2$parameter[2],2),
      P_Value = test2$p.value
    )
  )
  
  # =====================================================
  # TEST 3
  # Region vs Occupation Tier
  # =====================================================
  
  design3 <- subset(
    design_q,
    worked_last_7days == "YES" &
      occupation_tier != "Other" &
      !is.na(geopolitical_zone)
  )
  
  test3 <- svychisq(
    ~geopolitical_zone + occupation_tier,
    design3,
    statistic = "F"
  )
  
  results <- rbind(
    results,
    data.frame(
      Quarter = q,
      Relationship = "Region vs Occupation Tier",
      F_Statistic = round(as.numeric(test3$statistic),2),
      Numerator_DF = round(test3$parameter[1],2),
      Denominator_DF = round(test3$parameter[2],2),
      P_Value = test3$p.value
    )
  )
  
}

# =====================================================
# Decision & Interpretation
# =====================================================

results$Decision <- ifelse(
  results$P_Value < 0.05,
  "Reject H₀",
  "Fail to Reject H₀"
)

results$Interpretation <- ifelse(
  results$P_Value < 0.05,
  "Significant association",
  "No significant association"
)

# =====================================================
# Display Version of P-values
# =====================================================

results$P_Value_Display <- ifelse(
  results$P_Value < 0.001,
  "<0.001",
  sprintf("%.4f", results$P_Value)
)

# =====================================================
# Select Columns for Table
# =====================================================

results_display <- results %>%
  select(
    Quarter,
    Relationship,
    F_Statistic,
    Numerator_DF,
    Denominator_DF,
    P_Value_Display,
    Decision,
    Interpretation
  )

print(results_display)

# =====================================================
# Beautiful Table
# =====================================================

table_gt <- results_display %>%
  gt() %>%
  tab_header(
    title = md("**Survey-weighted Rao-Scott Chi-square Tests**"),
    subtitle = "Nigeria Labour Force Survey (2024–2025)"
  ) %>%
  cols_label(
    Quarter = "Quarter",
    Relationship = "Relationship",
    F_Statistic = "F Statistic",
    Numerator_DF = "Num DF",
    Denominator_DF = "Den DF",
    P_Value_Display = "P-value",
    Decision = "Decision",
    Interpretation = "Interpretation"
  ) %>%
  tab_style(
    style = list(
      cell_fill(color = "#1A5276"),
      cell_text(color = "white", weight = "bold")
    ),
    locations = cells_column_labels(everything())
  ) %>%
  opt_row_striping() %>%
  tab_options(
    table.background.color = "#FDFEFE",
    heading.background.color = "#1A5276",
    table.border.top.color = "#1A5276",
    table.border.bottom.color = "#1A5276"
  )

table_gt

# =====================================================
# Save Outputs
# =====================================================

gtsave(table_gt, "rao_scott_results.html")
gtsave(table_gt, "rao_scott_results.png")
gtsave(table_gt, "rao_scott_results.pdf")

cat("\nFinished Successfully!\n")
