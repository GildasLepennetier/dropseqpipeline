args <- commandArgs(TRUE)

RawReadFile = "UnfilteredReadCount.txt"

BarcodeFile = args[1]

RawReads = read.table(RawReadFile,header=F,sep="\t",fill=NA)
rawData = unlist(strsplit(as.character(RawReads[,1]),"XC:Z:"))
ReadCounts = as.numeric(trimws(rawData[seq(1,length(rawData),2)]))
Samples  = as.character(rawData[seq(2,length(rawData),2)])
Rawdata = data.frame(ReadCounts=ReadCounts,Sample=Samples)



barcodesUsed = as.character(read.table(BarcodeFile,sep="\t",header=F)[,1])


CountMat = read.table("DGE_Matrix.txt",header=T,sep="\t")
SumStat = read.table("Summary.txt",header=F,sep="\t")
barcodesCount = trimws(unlist(strsplit(as.character(SumStat[,1]),"XC:Z:")))
CountsPerFeature = barcodesCount[seq(1,length(barcodesCount),2)]
BarcodePerFeature = barcodesCount[seq(2,length(barcodesCount),2)]

SumStat = data.frame(Counts=as.numeric(CountsPerFeature),Barcode=BarcodePerFeature,Feature=as.character(SumStat[,2]))



ReducedMat = SumStat[SumStat[,"Barcode"] %in% barcodesUsed,]



InfoMat = data.frame(Barcode=barcodesUsed,Exonic=0,Intronic=0,Intergenic=0)
rownames(InfoMat) = InfoMat[,"Barcode"]


for (i in barcodesUsed){
          mat = ReducedMat[ReducedMat[,"Barcode"]==i,]
          coding=  mat[mat[,"Feature"]=="XF:Z:CODING","Counts"] +  mat[mat[,"Feature"]=="XF:Z:EXONIC","Counts"] +mat[mat[,"Feature"]=="XF:Z:UTR","Counts"]
          intronic =  mat[mat[,"Feature"]=="XF:Z:INTRONIC","Counts"] 
          intergenic =  mat[mat[,"Feature"]=="XF:Z:INTERGENIC","Counts"]
          if(!identical(numeric(0),coding))
             {
             InfoMat[i,"Exonic"] = coding
             }
          if(!identical(numeric(0),intronic))
             {   
             InfoMat[i,"Intronic"] = intronic
             }
          if(!identical(numeric(0),intergenic))
             {   
             InfoMat[i,"Intergenic"]=intergenic
             }
          } 
          



#InfoMat = data.frame(Barcode=barcodesUsed,Exonic=Exonic,Intronic=Intronic,Intergenic=Intergenic)
RawMat = Rawdata[Rawdata[,"Sample"] %in% barcodesUsed,]


merged  = merge(RawMat,InfoMat,by.x="Sample",by.y="Barcode")
UMICount = apply(CountMat[,as.character(merged[,"Sample"])],2,sum)
merged = data.frame(merged,UmiCount=UMICount)



colors =c("#D7CEC7","#565656","#76323F","#C09F80")

A = merged[,c("Exonic","Intronic","Intergenic","UmiCount")]/merged[,"ReadCounts"]
B = t(as.matrix(A[,c("Exonic","Intronic","Intergenic")]))
D = rbind(1-apply(B,2,sum),B)
rownames(D) =  c("NotMapped","Exonic","Intronic","Intergenic")
D = D[c("Exonic","Intronic","Intergenic","NotMapped"),]


tiff("SummaryBarplot.tiff",2600,1200,res=150)
x = barplot(D,col=colors,ylim=c(0,1.6),las=3)
barplot(merged[,"UmiCount"]/merged[,"ReadCounts"],col="#4682b4",add=T,xlab="",ylab="")
legend("topleft",c(rownames(D),"UMI"),col=c("#D7CEC7","#565656","#76323F","#C09F80","#4682b4"),pch=c(15,15,15,15,15),bty="n")
text(x,1.15,apply(InfoMat[,2:4],1,sum),srt=90)
dev.off()


Ordering = order(merged[,6])


tiff("BarplotReadCounts.tiff",1200,800,res=150)
barplot(merged[Ordering,2],col=colors[3])
barplot(merged[Ordering,6],add=T,col="#4682b4")
legend("topleft",c("Total Reads","UMI"),pch=c(15,15),col=c(colors[3],"#4682b4"),bty="n")
dev.off()

write.table(merged,file="ReadCountDistribution.txt",quote=F,sep="\t",row.names=F,col.names=T)


