# Get current file path
CURR_FILE_PATH <- getwd()

FFDATOOLS <- paste(CURR_FILE_PATH, "/ffdatools", sep="")

septdata_path = paste(FFDATOOLS, "/counts/tcount-bglsep_1.txt", sep="")
septdata<-read.delim(septdata_path)
plot(septdata$CWIN,septdata$COUNT,xlab = "CWIN",ylab = "count",col="blue",type = "ol",xlim = c(0,300),ylim = c(0,1200))
title(main="September data")

octdata_path = paste(FFDATOOLS, "/counts/tcount-bgloct_1.txt", sep="")
octdata<-read.delim(octdata_path,header = FALSE)
plot(octdata$V1,octdata$V2,xlab = "CWIN",ylab = "count",col="blue",type = "ol",xlim = c(0,300),ylim = c(0,600))
title(main="October data")

##Analisi aggiuntive (inutilizzato nella versione finale) ############
### Si potrebbe usare la differenza tra un valore di count e il successivo per vedere quando finisce di 
### variare in maniera significativa

# calcola la differenza tra i valori successivi di count
diff.countsept <- -(diff(septdata$COUNT))
diff.countoct <- -(diff(octdata$V2))

# aggiungi NA alla fine per allineare con i valori di CWIN, o all'inizio se fai inverso
diff.countsept <- c(diff.countsept,NA)
diff.countoct <- c(diff.countoct,NA)

# crea il grafico
plot(septdata$CWIN, diff.countsept, xlab = "CWIN", ylab = "difference in count", col="blue", type = "o", xlim = c(0,300), ylim = c(0,300))
title(main = "Variation in CWIN - September")
plot(octdata$V1, diff.countoct, xlab = "CWIN", ylab = "difference in count", col="blue", type = "o", xlim = c(0,300), ylim = c(0,150))
title(main = "Variation in CWIN - October")

### fine parte che non c'è nell'homework ###

##Qua si esegue lo script per generare interarrivals

###importiamo interarrivals
pathsept<- paste(FFDATOOLS,"/tuples-bglsep_1-120/interarrivals.txt", sep="")
pathoct<- paste(FFDATOOLS, "/tuples-bgloct_1-100/interarrivals.txt", sep="")

interarrivals<-read.delim(pathsept,header = FALSE)
interarrivals<-read.delim(pathoct,header = FALSE)

#Calcolo ecdf
TTF<-ecdf(interarrivals$V1)

#knots ci restituisce i punti in cui una certa funzione è stata valutata
#l'output sarà quindi una parte di tutti gli interarrivi
t<-knots(TTF)
par(cex=1.3)
plot(t,TTF(t),col="red",xlim=c(0,50000),type="ol",xlab = "time(s)",ylab = "P ( X<X(t) )")
title(main="ECDF - October interarrivals")

#questa è la reliability empirica
r<- 1-TTF(t)
title(main="ECDF and Reliability - R62-M0-N0 interarrivals")
legend("topright", legend = c("Reliability", "ECDF"), col = c("blue", "red"), pch = 1)

lines(t,r,col="blue",xlim=c(0,50000),type="ol",xlab = "time(s)",ylab = "p")

#sovrapponiamo il modello ai punti sperimentali
plot(t,r,xlim=c(0,40000))

expfit<-nls(r~exp(-(l*t)), start = list(l=1/mean(interarrivals$V1)))
weifit<-nls(r~exp(-(l*t)^a), start = list(l=1/mean(interarrivals$V1), a=0.9))

hyperexp1 <- nls(r~0.5*exp(-(l1*t))+0.5*exp(-(l2*t)), start = list(
  l1=1/mean(interarrivals$V1),
  l2=0.1/mean(interarrivals$V1) 
))

hyperexp2 <- nls(r~0.3*exp(-(l1*t))+0.7*exp(-(l2*t)), start = list(
  l1=1/mean(interarrivals$V1),
  l2=0.1/mean(interarrivals$V1) 
))

hyperexp3 <- nls(r~0.5*exp(-(l1*t))+0.3*exp(-(l2*t))+0.2*exp(-(l3*t)), start = list(
  l1=0.1/mean(interarrivals$V1),
  l2=1/mean(interarrivals$V1),
  l3=0.9/mean(interarrivals$V1)
))

lines( t, predict(hyperexp1), col="green", lwd=2)
lines( t, predict(hyperexp2), col="magenta", lwd=2)
lines( t, predict(hyperexp3), col="orange", lwd=2)

legend("topright", legend = c("ECDF","hyperexp 1","hyperexp 2","hyperexp 3"), col = c("black","green","magenta","orange"), pch = 1)
title("Models fitting - Hyperexponential variations (zoomed)")

lines( t, predict(expfit), col="blue", lwd=2)
lines( t, predict(weifit), col="red", lwd=2)

legend("topright", legend = c("ECDF","expfit", "weifit","hyperexp","hyperexp","hyperexp"), col = c("black","blue", "red","green","magenta","orange"), pch = 1)
title("Models fitting (zoomed)")
options(scipen = 999)

print(coef(expfit))
print(coef(weifit))
print(coef(hyperexp1))
print(coef(hyperexp2))
print(coef(hyperexp3))

##tets di ks
ks.test(r,predict(expfit))
ks.test(r,predict(weifit))
ks.test(r,predict(hyperexp1))
ks.test(r,predict(hyperexp2))
ks.test(r,predict(hyperexp3))

##rework qqplot
month<-"September"
month<-"October"
vis_path<-paste(CURR_FILE_PATH,"/Visualizations/September MOdels/",sep="")
vis_path<-paste(CURR_FILE_PATH,"/Visualizations/October Models/",sep="")

models <- list(expfit, weifit, hyperexp1, hyperexp2, hyperexp3)
model_names <- c("expfit", "weifit", "hyperexp1", "hyperexp2", "hyperexp3")

for (i in 1:length(models)) {
  model <- models[[i]]
  model_name <- model_names[i]
  
  residuals <- residuals(model)
  
  plot_title <- paste0("Residuals vs Predicted - ", month," ",model_name)
  png(filename = paste0(vis_path, plot_title, '.png'),width = 1000,height = 800)
  predicted_response <- predict(model)
  plot(predicted_response, residuals, 
       xlab = "Predicted", ylab = "Residuals", 
       main = plot_title)
  abline(h = 0, col = "red")
  dev.off()
  
  plot_title <- paste0("Residuals vs Experiment Number - ", month," ",model_name)
  png(filename = paste0(vis_path, plot_title, '.png'),width = 1000,height = 800)
  plot(residuals, 
       xlab = "Experiment Number", ylab = "Residuals", 
       main = plot_title)
  abline(h = 0, col = "red")
  dev.off()
  
  # Aggiunta del QQ Plot
  plot_title_qq <- paste0("QQ Plot - ", month," ",model_name)
  png(filename = paste0(vis_path, plot_title_qq, '.png'),width = 1000,height = 800)
  qqnorm(residuals, main = plot_title_qq, ylab = "Quantiles of residuals")
  qqline(residuals, col = "red")
  dev.off()
}




### Analisi su interarrivals ########################

# Carica i dati
interarrivals_sept<-read.delim(pathsept,header = FALSE)
interarrivals_oct<-read.delim(pathoct,header = FALSE)

months <- list("September" = interarrivals_sept$V1, "October" = interarrivals_oct$V1)

for(month in names(months)){
  data <- months[[month]]
  
  # Calcola le statistiche descrittive
  print(paste("Summary for", month))
  print(summary(data))
  
  mean_time <- mean(data)
  
  median_time <- median(data)
  
  sd_time <- sd(data)
  
  # Crea un istogramma
  png(filename = paste0("C:\\Users\\fonde\\Documents\\GitHub\\DataScienceHomeworks\\Homework1\\Visualizations\\Interarrival times - ", month, ".png"))
  hist(data, breaks = 30, main = paste("Interarrival times -", month),freq = FALSE,
       xlab = "Interarrival Time (seconds)",
       col = "lightblue", border = "black")
  lines(density(data), col="red", lwd=2)
  dev.off()
  
  # Crea un grafico della distribuzione con i valori di tendenza centrale
  png(filename = paste0("C:\\Users\\fonde\\Documents\\GitHub\\DataScienceHomeworks\\Homework1\\Visualizations\\Interarrival times distribution - ", month, ".png"))
  plot(density(data), main = paste("Interarrival times distribution -", month),
       xlab = "Interarrival Time (seconds)")
  abline(v = mean_time, col = "red", lwd = 2)  # Media
  abline(v = median_time, col = "blue", lwd = 2)  # Mediana
  
  # Aggiungi una legenda
  legend("topright", legend = c("Mean", "Median"),
         col = c("red", "blue"), lwd = 2)
  dev.off()
}

# Crea un boxplot combinato
png(filename = "C:\\Users\\fonde\\Documents\\GitHub\\DataScienceHomeworks\\Homework1\\Visualizations\\Interarrival Times - September & October.png")
boxplot(interarrivals_sept$V1, interarrivals_oct$V1, main = "Interarrival Times - September & October",
        boxwex=0.4, ylab = "Interarrival Time (seconds)", col = c("lightblue", "lightgreen"),
        names = c("September", "October"))
dev.off()



