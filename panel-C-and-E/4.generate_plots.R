library(data.table)
library(ggplot2)

files_dir <- list.files("./")
files_dir <- files_dir[grep("txt", files_dir)]
files_dir

dt_list <- list()
for(file_dir in files_dir){
  dt_rport <- read.table(file_dir) |> as.data.table()
  names (dt_rport) <-c("time_elapsed", "cpu", "memory_usage", "mem_vir")
  if(sub("^(.)-.*$", "\\1", file_dir) == 1){
    dt_rport[, Run := "GEDI 1.0"]
  } else {
    ID_flag <- paste0("GEDI 2.0\n", sub("^.-(.*)-.*txt$", "\\1", file_dir), " Thread(s)")
    dt_rport[, Run := ID_flag]
  }
  dt_rport[, max_mem := max(memory_usage)]
  dt_rport[, max_time := max(time_elapsed)]
  dt_list[[file_dir]] <- dt_rport
}

repor_dt <- rbindlist(dt_list)
repor_dt$max_time <- (repor_dt$max_time / 60 )

ggplot(data = repor_dt, 
       aes(x = time_elapsed, y = memory_usage, color = Run)) +
  geom_line() +
  theme_bw() +
  facet_wrap(~Run, scales ="free_x")


ggplot(repor_dt, aes(fill=Run, y=max_time, x=reorder(Run, max_time))) + 
  geom_bar(position="dodge", stat="identity") +
  theme_bw() + 
  theme(axis.text.x = element_text(hjust = 1, angle = 45))
  


