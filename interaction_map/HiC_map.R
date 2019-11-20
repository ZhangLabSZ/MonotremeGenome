rm(list = ls())
graphics.off()

library(ggplot2)
library(RColorBrewer)
#library(multiplot)

theme <- theme_bw()+
  theme(plot.title = element_text(hjust = 0.5),
        panel.background = element_rect(fill = 'white', colour = 'black'),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank())

###XY
md <- read.table("example/new.matrix", header = FALSE)
#head(md)
md$V4 <- sub("chr","",md$V4)
md$V5 <- sub("chr","",md$V5)
chr <- union(as.character(unique(md$V4)),as.character(unique(md$V5)))
md$V6 <- "yes"
###no
md[(md$V4=="X1_nonPAR"|md$V4=="X1_PAR-L"|md$V4=="Y1_PAR-L") & (md$V5=="X1_nonPAR"|md$V5=="X1_PAR-L"|md$V5=="Y1_PAR-L"),]$V6 <- "no"
#md[(md$V4=="Y1_PAR-R"|md$V4=="X2_PAR-L"|md$V4=="X2_nonPAR"|md$V4=="X2_PAR-R"|md$V4=="Y2_PAR-L") & (md$V5=="Y1_PAR-R"|md$V5=="X2_PAR-L"|md$V5=="X2_nonPAR"|md$V5=="X2_PAR-R"|md$V5=="Y2_PAR-L"),]$V6 <- "no"
#md[(md$V4=="Y2_PAR-R"|md$V4=="X3_PAR-L"|md$V4=="X3_nonPAR"|md$V4=="X3_PAR-R"|md$V4=="Y3_PAR-L") & (md$V5=="Y2_PAR-R"|md$V5=="X3_PAR-L"|md$V5=="X3_nonPAR"|md$V5=="X3_PAR-R"|md$V5=="Y3_PAR-L"),]$V6 <- "no"
#md[(md$V4=="Y3_PAR-R"|md$V4=="X4_PAR-L"|md$V4=="X4_nonPAR") & (md$V5=="Y3_PAR-R"|md$V5=="X4_PAR-L"|md$V5=="X4_nonPAR"),]$V6 <- "no"
#md[(md$V4=="Y4_PAR-R"|md$V4=="X5_PAR-L"|md$V4=="X5_nonPAR"|md$V4=="X5_PAR-R"|md$V4=="Y5_PAR-L") & (md$V5=="Y4_PAR-R"|md$V5=="X5_PAR-L"|md$V5=="X5_nonPAR"|md$V5=="X5_PAR-R"|md$V5=="Y5_PAR-L"),]$V6 <- "no"
###no
md$V7 <- sub("_.*","",md$V4)
md$V8 <- sub("_.*","",md$V5)
chr1 <- union(as.character(unique(md$V7)),as.character(unique(md$V8)))
for (i in seq(1,length(chr1))) {
  md[md$V7==chr1[i] & md$V8==chr1[i],]$V6 <- "no"
}
###na
md[(md$V4=="X1_PAR-L"|md$V4=="Y1_PAR-L"|md$V4=="Y1_nonPAR"|md$V4=="Y1_PAR-R"|md$V4=="X2_PAR-L") & (md$V5=="X1_PAR-L"|md$V5=="Y1_PAR-L"|md$V5=="Y1_nonPAR"|md$V5=="Y1_PAR-R"|md$V5=="X2_PAR-L") & md$V6!="no",]$V6 <- "na"
#md[(md$V4=="X2_PAR-R"|md$V4=="Y2_PAR-L"|md$V4=="Y2_nonPAR"|md$V4=="Y2_PAR-R"|md$V4=="X3_PAR-L") & (md$V5=="X2_PAR-R"|md$V5=="Y2_PAR-L"|md$V5=="Y2_nonPAR"|md$V5=="Y2_PAR-R"|md$V5=="X3_PAR-L") & md$V6!="no",]$V6 <- "na"
#md[(md$V4=="X3_PAR-R"|md$V4=="Y3_PAR-L"|md$V4=="Y3_nonPAR"|md$V4=="Y3_PAR-R"|md$V4=="X4_PAR-L") & (md$V5=="X3_PAR-R"|md$V5=="Y3_PAR-L"|md$V5=="Y3_nonPAR"|md$V5=="Y3_PAR-R"|md$V5=="X4_PAR-L") & md$V6!="no",]$V6 <- "na"
#md[(md$V4=="Y4_nonPAR"|md$V4=="Y4_PAR-R"|md$V4=="X5_PAR-L") & (md$V5=="Y4_nonPAR"|md$V5=="Y4_PAR-R"|md$V5=="X5_PAR-L") & md$V6!="no",]$V6 <- "na"
#md[(md$V4=="X5_PAR-R"|md$V4=="Y5_PAR-L"|md$V4=="Y5_nonPAR") & (md$V5=="X5_PAR-R"|md$V5=="Y5_PAR-L"|md$V5=="Y5_nonPAR") & md$V6!="no",]$V6 <- "na"


md$V4 <- md$V6

interval <- (max(md$V3)-min(md$V3))/200
md$V5 <- 0
md[md$V4=="no",]$V5 <- round(md[md$V4=="no",]$V3/interval)+1
md[md$V4=="yes",]$V5 <- round(md[md$V4=="yes",]$V3/interval)+10001
md[md$V4=="na",]$V5 <- round(md[md$V4=="na",]$V3/interval)+10000001

colfunc1<-colorRampPalette(c(brewer.pal(9,"Greys")[2],brewer.pal(9,"Greys")[5]))  ###grey
colour1 <- colfunc1(201)

colfunc2<-colorRampPalette(c(brewer.pal(9,"Reds")[3],brewer.pal(9,"Reds")[6]))  ###red
colour2 <- colfunc2(201)

colfunc3<-colorRampPalette(c(brewer.pal(9,"Greys")[4],brewer.pal(9,"Greys")[7]))  ###green
colour3 <- colfunc3(201)
colour <- c(colour1,colour2,colour3)


#named vector
names(colour) <- c(seq(1,201),seq(10001,10201),seq(10000001,10000201))
md$V6 <- colour[as.character(md$V5)]

md$V7 <- 1
md$V8 <- 1


md <- md[md$V5!=1 & md$V5!=10001 & md$V5!=10000001, ]
width <- 0.015*max(md$V1)


p1 <- ggplot(md)+geom_point(data=md,aes(x=V1,y=V2),colour=md$V6, alpha=md$V8,size=md$V7,show.legend = FALSE)+
  xlab("")+
  ylab("")+ 
  #guides(color=FALSE)+
  theme

png("example/p1.png",width = 500,height = 480)
p1
dev.off()
