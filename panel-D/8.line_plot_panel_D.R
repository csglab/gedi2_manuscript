#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(ggplot2)
  library(data.table)
  library(Matrix)
  library(patchwork)
})


tex.dirs <- "../panel-C-and-E/"

files_dir <- list.files(tex.dirs)
files_dir <- files_dir[grep("txt", files_dir)]

save.dir <- "figures"


ewma <- function(vec, momentum = 0.9) {
  # Initialize an output vector of the same length
  moving_avg <- numeric(length(vec)) 
  # The first average is just the first value
  moving_avg[1] <- vec[1]
  # Loop through the rest of the vector
  for (i in 2:length(vec)) {
    moving_avg[i] <- momentum * moving_avg[i-1] + (1 - momentum) * vec[i]
  }
  return(moving_avg)
}

dt_list <- list()
for(file_dir in files_dir){
    dt_rport <- read.table(file.path(tex.dirs, file_dir)) |> as.data.table()
    names(dt_rport) <- c("time_elapsed", "cpu", "memory_usage", "mem_vir")
    if(sub("^(.)-(.*)-(.*).txt$", "\\1", file_dir) == 1){
        dt_rport[, Run := "original"]
        dt_rport[, cell_number := sub("^(.)-(.*)-(.*).txt$", "\\3", file_dir)]
    } else {
        ID_flag <- paste0("new_imp_", sub("^(.)-(.*)-(.*).txt$", "\\2", file_dir), "_threads")
        dt_rport[, Run := ID_flag]
        dt_rport[, cell_number := sub("^(.)-(.*)-(.*).txt$", "\\3", file_dir)]
    }
    dt_rport[, avg_mem := ewma(memory_usage, momentum = 0.5)]
    dt_rport[, max_mem := max(memory_usage)]
    dt_rport[, max_time := max(time_elapsed)]
    dt_list[[file_dir]] <- dt_rport
}

report_dt <- rbindlist(dt_list)
report_dt$max_time <- as.integer(report_dt$max_time)

# Extract execution time for each implementation and cell number
time_summary <- report_dt[, .(
  execution_time = first(max_time)
), by = .(Run, cell_number)]

# Sort implementations
time_summary[, thread_num := ifelse(Run == "original", 0, 
                                     as.numeric(gsub(".*_(\\d+)_threads", "\\1", Run)))]
time_summary <- time_summary[order(cell_number, thread_num)]
time_summary[, Run := factor(Run, levels = unique(Run[order(thread_num)]))]

# Calculate speedup
time_summary[, baseline_time := execution_time[Run == "original"], by = cell_number]
time_summary[, speedup := baseline_time / execution_time]

# Colors
n_impl <- length(unique(time_summary$Run))
colors <- colorRampPalette(c("#808080", "#d4f1d4", "#b8e6b8", "#8dd98d", 
                              "#62cc62", "#4db84d", "#2e8b2e"))(n_impl)
names(colors) <- levels(time_summary$Run)

# Plot 1: Execution Time
p_time <- ggplot(time_summary, aes(x = Run, y = execution_time, fill = Run)) +
  geom_bar(stat = "identity", width = 0.7, color = "black", linewidth = 0.3) +
  geom_text(aes(label = paste0(execution_time, "s")), 
            vjust = -0.5, size = 2.5, fontface = "bold") +
  scale_fill_manual(values = colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  facet_wrap(~ cell_number, scales = "free_y", ncol = 3,
             labeller = labeller(cell_number = function(x) paste(format(as.numeric(x), big.mark = ","), "Cells"))) +
  labs(title = "A) Execution Time Comparison",
       x = NULL, y = "Time (seconds)") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 11, hjust = 0),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        strip.text = element_text(face = "bold", size = 9),
        panel.grid.major.x = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

# Plot 2: Speedup Factor
p_speedup <- ggplot(time_summary, aes(x = Run, y = speedup, fill = Run)) +
  geom_bar(stat = "identity", width = 0.7, color = "black", linewidth = 0.3) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.6) +
  geom_text(aes(label = sprintf("%.2fx", speedup)), 
            vjust = -0.5, size = 2.5, fontface = "bold") +
  scale_fill_manual(values = colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  facet_wrap(~ cell_number, scales = "free_y", ncol = 3,
             labeller = labeller(cell_number = function(x) paste(format(as.numeric(x), big.mark = ","), "Cells"))) +
  labs(title = "B) Speedup Relative to Original Implementation",
       x = "Implementation", y = "Speedup Factor") +
  theme_minimal(base_size = 10) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 11, hjust = 0),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
        strip.text = element_text(face = "bold", size = 9),
        panel.grid.major.x = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

# Prepare data for combined speedup plot
speedup_compare <- time_summary[, .(Run, cell_number, speedup, thread_num)]
speedup_compare[, Implementation := ifelse(Run == "original", "Original", 
                                           paste0(thread_num, " threads"))]
speedup_compare[, Dataset := paste0(format(as.numeric(cell_number), big.mark = ","), " Cells")]

# Create proper factor ordering
speedup_compare[, Implementation := factor(Implementation, 
                                           levels = c("Original", paste0(sort(unique(thread_num[thread_num > 0])), " threads")))]

p_speedup_compare <- ggplot(speedup_compare, aes(x = Implementation, y = speedup, fill = Implementation)) +
  geom_bar(stat = "identity", width = 0.7, color = "black", linewidth = 0.3) +
  geom_hline(yintercept = 1, linetype = "dashed", color = "gray40", linewidth = 0.6) +
  geom_text(aes(label = sprintf("%.2f×", speedup)), 
            vjust = -0.5, size = 3, fontface = "bold") +
  scale_fill_manual(values = colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15)), breaks = seq(0, 8, 1)) +
  facet_wrap(~ Dataset, ncol = 2) +
  labs(title = "Speedup Factor Comparison Across Dataset Sizes",
       x = "Implementation", y = "Speedup Factor (×)") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
        axis.text.x = element_text(angle = 45, hjust = 1, size = 9),
        strip.text = element_text(face = "bold", size = 11),
        panel.grid.major.x = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

# Peak memory for all implementations
peak_memory <- report_dt[, .(peak_memory = first(max_mem)), by = .(Run, cell_number)]
peak_memory[, Implementation := ifelse(Run == "original", "Original", 
                                       paste0(sub(".*_(\\d+)_.*", "\\1", Run), " threads"))]
peak_memory[, Dataset := paste0(format(as.numeric(cell_number), big.mark = ","), " Cells")]
peak_memory[, thread_num := ifelse(Run == "original", 0, as.numeric(sub(".*_(\\d+)_.*", "\\1", Run)))]
peak_memory <- peak_memory[order(thread_num)]
peak_memory[, Implementation := factor(Implementation, levels = unique(Implementation))]

p_peak <- ggplot(peak_memory, aes(x = Dataset, y = peak_memory, fill = Implementation)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), 
           width = 0.7, color = "black", linewidth = 0.3) +
  geom_text(aes(label = sprintf("%.0f", peak_memory)), 
            position = position_dodge(width = 0.8),
            vjust = -0.5, size = 2.5, fontface = "bold") +
  scale_fill_manual(values = colors) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Peak Memory Usage for All Implementations",
       x = "Dataset Size", y = "Peak Memory (MB)", fill = "Implementation") +
  theme_minimal(base_size = 11) +
  theme(plot.title = element_text(face = "bold", size = 13, hjust = 0.5),
        legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

# Memory fluctuations (for original, 1, 2 threads only)
memory_data <- report_dt[Run %in% c("original", "new_imp_1_threads", "new_imp_2_threads")]
memory_data[, label := paste0(
  ifelse(Run == "original", "Original", 
         paste0("New (", sub(".*_(\\d+)_.*", "\\1", Run), " thread", 
                ifelse(sub(".*_(\\d+)_.*", "\\1", Run) == "1", "", "s"), ")")),
  "\n(", format(as.numeric(cell_number), big.mark = ","), " Cells)"
)]

mem_colors <- c("original" = "#808080", "new_imp_1_threads" = "#d4f1d4", "new_imp_2_threads" = "#b8e6b8")

p_memory_fluct <- ggplot(memory_data, aes(x = time_elapsed, y = memory_usage, color = Run)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = mem_colors) +
  facet_wrap(~ label, ncol = 3, scales = "free") +
  labs(title = "Memory Usage Fluctuations", 
       x = "Time (seconds)", y = "Memory (MB)") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", hjust = 0.5),
        strip.text = element_text(face = "bold", size = 9),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

p_memory_smooth <- ggplot(memory_data, aes(x = time_elapsed, y = avg_mem, color = Run)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(values = mem_colors) +
  facet_wrap(~ label, ncol = 3, scales = "free") +
  labs(title = "Smoothed Memory Usage (EWMA)", 
       x = "Time (seconds)", y = "Memory (MB)") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", hjust = 0.5),
        strip.text = element_text(face = "bold", size = 9),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

# Memory fluctuations for 100K cells only (black lines)
memory_data_100k <- report_dt[Run %in% c("original", "new_imp_1_threads", "new_imp_2_threads") & 
                               cell_number == "100000"]
memory_data_100k[, label := ifelse(Run == "original", "Original", 
                                   paste0("New (", sub(".*_(\\d+)_.*", "\\1", Run), " thread", 
                                          ifelse(sub(".*_(\\d+)_.*", "\\1", Run) == "1", "", "s"), ")"))]

p_memory_100k <- ggplot(memory_data_100k, aes(x = time_elapsed, y = memory_usage)) +
  geom_line(linewidth = 0.8, color = "black") +
  facet_wrap(~ label, ncol = 3, scales = "free") +
  labs(title = "Memory Usage Fluctuations (100,000 Cells)", 
       x = "Time (seconds)", y = "Memory (MB)") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", hjust = 0.5),
        strip.text = element_text(face = "bold", size = 9),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

p_memory_smooth_100k <- ggplot(memory_data_100k, aes(x = time_elapsed, y = avg_mem)) +
  geom_line(linewidth = 0.8, color = "black") +
  facet_wrap(~ label, ncol = 3, scales = "free") +
  labs(title = "Smoothed Memory Usage - EWMA (100,000 Cells)", 
       x = "Time (seconds)", y = "Memory (MB)") +
  theme_minimal(base_size = 11) +
  theme(legend.position = "none",
        plot.title = element_text(face = "bold", hjust = 0.5),
        strip.text = element_text(face = "bold", size = 9),
        panel.border = element_rect(color = "black", fill = NA, linewidth = 0.5))

# Combined time performance plot
combined_time <- p_time / p_speedup
ggsave(file.path(save.dir, "time_performance_all.pdf"), combined_time, width = 12, height = 8, dpi = 300, device = cairo_pdf)

# Speedup comparison
ggsave(file.path(save.dir, "speedup_comparison_datasets.pdf"), p_speedup_compare, width = 10, height = 5, dpi = 300, device = cairo_pdf)

# Memory plots
ggsave(file.path(save.dir, "peak_memory_all.pdf"), p_peak, width = 10, height = 6, dpi = 300, device = cairo_pdf)
ggsave(file.path(save.dir, "memory_fluctuations_all.pdf"), p_memory_fluct, width = 12, height = 8, dpi = 300, device = cairo_pdf)
ggsave(file.path(save.dir, "memory_smooth_all.pdf"), p_memory_smooth, width = 12, height = 8, dpi = 300, device = cairo_pdf)
ggsave(file.path(save.dir, "memory_fluctuations_100k.pdf"), p_memory_100k, width = 12, height = 4, dpi = 300, device = cairo_pdf)
ggsave(file.path(save.dir, "memory_smooth_100k.pdf"), p_memory_smooth_100k, width = 12, height = 4, dpi = 300, device = cairo_pdf)

# Display all plots
print(combined_time)
print(p_speedup_compare)
print(p_peak)
print(p_memory_fluct)
print(p_memory_smooth)
print(p_memory_100k)
print(p_memory_smooth_100k)

