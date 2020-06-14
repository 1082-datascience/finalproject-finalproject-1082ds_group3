png(file="/docs/XGBoost_validation.png")
data <- read.csv(paste0(getwd(), "/docs/performance_XGBoost.csv"))
x = data[,1]
y = data[,3]
plot(x, y, type = "l",main="XGBoost cross validation",xlab="Round",ylab="Test error")# ylim = c(-5, 20))
dev.off()

rm(list = ls())

png(file="/docs/Regression_validation.png")
data <- read.csv(paste0(getwd(), "/docs/performance_glm.csv"))
x = data[,1]
y = data[,2]
y2 = data[,3]
plot(x, y, type = "b",main="Linear regression validation", xlab="Fold",ylab="Accurary",ylim=c(0.65,0.92))# ylim = c(-5, 20))
lines(x,y2,type="b",col="red")
legend(8, 0.91, legend=c("Public", "Private"),
       col=c("black", "red"), lty=1:1, cex=0.8)

dev.off()