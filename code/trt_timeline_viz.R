## ------------------------------------------------------------------------------------------
##
## Script name: Treatment timeline data visualization
##
## Purpose of script: Show an example of code to make a longitudinal treatment timeline to visualize time-varying treatment patterns.
##
## Author: Katherine Hoffman
##
## Date Created: 2022-06-08
##
## Author: Katherine Hoffman, 2022
## Email: kah2797@med.cornell.edu
##
## ------------------------------------------------------------------------------------------
##
## Notes: The data set and code for n=30 patients is also used in a corresponding blog post with step by step instructions.
## www.khstats.com/blog/trt-timelines/multiple-vars
## 
## ------------------------------------------------------------------------------------------

## load necessary libraries

library(tidyverse)
library(gt)

dat_long  <- read_rds(here::here("data/dat_trt_timeline.rds"))

## ------------------------------------------------------------------------------------------

# define colors for all geometries with a color argument
cols <- c("Severe hypoxia" = "#b24745", # red
          "Intubated" = "darkslateblue", # navy
          "Not intubated" = "#74aaff", # lighter blue
          "Steroids"="#ffd966", # gold
          "Death" = "black") 
shapes <- c("Severe hypoxia" = 21,
            "Steroids" = 15, # square
            "Death" = 4) # cross # empty circle (control inside with fill argument if desired)

shape_override <- c(21, NA, NA, 15, 4) # order matches `cols`: hypoxia, intubation (yes/no), steroids, death
line_override <- c(NA,1,1,NA,NA) # order matches `cols`: hypoxia, intubation (yes/no), steroids, death
stroke_override <- c(1,1,1,1,1.5) # order matches `cols`: hypoxia, intubation (yes/no), steroids, death
size_override <- c(2.5,2.5,2.5,2,2) # order matches `cols`: hypoxia, intubation (yes/no), steroids, death

dat_swim <- 
  dat_long |>
  mutate(severe_this_day = case_when(severe == 1 ~ day),
         steroids_this_day = case_when(steroids == 1 ~ day),
         death_this_day = case_when(death == 1 ~ day)) %>%
  group_by(id) |>
  mutate(max_day = max(day)) |>
  ungroup() |>
  nest(cols = day:death_this_day) |>
  arrange(max_day) |>
  mutate(id_sorted = factor(row_number())) |>
  unnest()

dat_swim |>
  ggplot() +
  geom_line(aes(x=day, y=id_sorted, col = intubation_status, group=id_sorted),
            size=1.8) +
  geom_point(aes(x=steroids_this_day, y=id_sorted, col="Steroids", shape="Steroids"), stroke=2) +
  geom_point(aes(x=severe_this_day, y=id_sorted, col="Severe hypoxia", shape="Severe hypoxia"), size=2, stroke=1.5) +
  geom_point(aes(x=death_this_day, y=id_sorted, col="Death", shape="Death"), size=2, stroke=1.5) +
  theme_bw() +
  scale_color_manual(values = cols, name="Patient Status") +
  scale_shape_manual(values = shapes, name = "Patient Status") +
  guides(color = guide_legend(
    override.aes = list(
      shape = shape_override,
      linetype = line_override)
  ),
  shape = "none"
  )+
  labs(x="Days since hospitalization",y="Patient\nnumber",title="Treatment Timelines for N=30 Patients") +
  scale_x_continuous(expand=c(0,0)) + # remove extra white space 
  theme(text=element_text(family="Poppins", size=11),
        title = element_text(angle = 0, vjust=.5, size=14, face="bold"),
        axis.title.y = element_text(angle = 0, vjust=.5, size=11, face="bold"),
        axis.title.x = element_text(size=11, face="bold", vjust=-0.5, hjust=0),
        axis.text.y = element_text(size=6, hjust=1.5),
        axis.ticks.y = element_blank(),
        legend.position = c(0.8, 0.24),
        legend.title = element_text(colour="black", size=13, face=4),
        legend.text = element_text(colour="black", size=10),
        legend.background = element_rect(size=0.5, linetype="solid", colour ="gray30"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank()
  ) 