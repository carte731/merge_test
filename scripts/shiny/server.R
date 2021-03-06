library(shiny)
library(genomeIntervals)
library(lattice)
library(Hmisc)
library(ape)
library(data.table)
options(shiny.maxRequestSize = -1)
thetas.headers <- c("(indexStart,indexStop)(firstPos_withData,lastPos_withData)(WinStart,WinStop)","Chr","WinCenter","tW","tP","tF","tH","tL","Tajima","fuf","fud","fayh","zeng","nSites")
fst.headers <- c("A", "AB", "f", "FST", "Pvar")
intersect.headers <- c("Chr","bp")
#thetas <- fread("~/RiceResults/allo_Diversity.thetas.gz.pestPG",sep = '\t')
# fst <- read.table(file="allo.indica.fst",
#                   sep="\t",
#                   col.names=fst.headers)
# intersect <- read.table(file="intersect.allo.indica_intergenic.txt",
#                         sep="\t",
#                         col.names=intersect.headers)
not.loaded <- TRUE

# Define server logic required to draw a histogram
shinyServer(


  function(input, output) {

    dataInputThetas = reactive({
      data <- input$userThetas
      path <- as.character(data$datapath)
      thetas <- fread(input=path, sep="\t")
      setnames(thetas,thetas.headers)
      return(thetas)
    })

    dataInputSFS = reactive({
      data <- input$userSFS
      path <- as.character(data$datapath)
      sfs <- exp(scan(path))
      return(sfs)

    })

    dataInputFst = reactive({
      data <- input$userFst
      path <- as.character(data$datapath)
      fst <- read.table(file=path,
                        sep="\t",
                        col.names=fst.headers
      )
      return(fst)
    })

    dataInputIntersect = reactive({
      data <- input$userIntersect
      path <- as.character(data$datapath)
      intersect <- read.table(file=path,
                              sep="\t",
                              col.names=intersect.headers
      )
      return(intersect)
    })

    dataInputAdmix = reactive({
      data <- input$userAdmix
      path <- as.character(data$datapath)
      admix <- t(as.matrix(read.table(path)))
      return(admix)

    })

    dataInputABBABABA = reactive({
      data <- input$userABBABABA
      path <- as.character(data$datapath)
      ABBABABA <- read.table(path, sep="\t", header=T)
      return(ABBABABA)

    })

    dataInputPCA = reactive({
      data <- input$userPCA
      path <- as.character(data$datapath)
      PCA <- read.table(path, header=F)
      return(PCA)
    })

    gffInput = reactive({
      data <- input$userAnnotations
      path <- as.character(data$datapath)
      gff <- readGff3(path)

      return(gff)

    })

    output$thetaChroms = renderUI({
      if(is.null(input$userThetas)){
        choices <- 10
      }
      else{
      thetas <- dataInputThetas()
      choices <- unique(thetas$Chr)
      }
      selectInput('thetaChrom', 'Chromosome to plot', choices)
    })

    output$thetaPlot <- renderPlot({
#       error handling code to provide a default dataset to graph
      thetas <- tryCatch({
        dataInputThetas()
      }, error = function(err) {
        thetas <- read.table(file="BKN_Diversity.thetas.gz.pestPG",
                             sep="\t",
                             col.names=thetas.headers)
      }
      )

      thetas <- subset(thetas,Chr==input$thetaChrom)
      if(input$annotations){
        validate(need(input$userAnnotations, 'Need GFF file before clicking checkbox!'))
        gff <- gffInput()
        gff.gene <- subset(gff, type="gene")
        gff.df <- data.frame(gff.gene,annotation(gff))
        gff.df.chr <- subset(gff.df, seq_name==thetas$Chr[1])
        if(length(gff.df.chr$seq_name)==0){
          stop("Annotation does not match graphed region. Please make sure the first column of your GFF file matches the Chr column of the .pestPG file.")
        }
        gff.df.gene <- subset(gff.df.chr, type=="gene")
      }

      if(input$subset) {
        thetas.plot <- subset(thetas, WinCenter > input$WinCenterLow & WinCenter < input$WinCenterHigh)
      }
      else {
        thetas.plot <- thetas
      }

      # remove nsites=0
      thetas.plot <- subset(thetas.plot, nSites != 0)
      # remove data points with less than 50 sites. Calculate minimum from data?
      if(input$rm.nsites) {
        thetas.plot <- subset(thetas.plot, nSites > input$nsites)
      }
      #divide thetas by the number of sites in each window
      thetas.plot$tW <- thetas.plot$tW/thetas.plot$nSites
      thetas.plot$tP <- thetas.plot$tP/thetas.plot$nSites
      thetas.plot$tF <- thetas.plot$tF/thetas.plot$nSites
      thetas.plot$tH <- thetas.plot$tH/thetas.plot$nSites
      thetas.plot$tL <- thetas.plot$tW/thetas.plot$nSites

      data <- switch(input$thetaChoice,
                     "Watterson's Theta" = thetas.plot$tW,
                     "Pairwise Theta" = thetas.plot$tP,
                     "Fu and Li's Theta" = thetas.plot$tF,
                     "Fay's Theta" = thetas.plot$tH,
                     "Maximum likelihood (L) Theta" = thetas.plot$tL
      )
      if(input$annotations) {
        plot(thetas.plot$WinCenter,
             data, t="p", pch=19,col=rgb(0,0,0,0.5),
             xlab="Position (bp)",
             ylab=paste(input$thetaChoice,"Estimator Value"),
             main=paste("Estimators of theta along chromosome", thetas$Chr[1])
        )

        rug(rect(gff.df.gene$X1, -1e2, gff.df.gene$X2, 0, col=rgb(0.18,0.55,0.8,0.75), border=NA))
        if(input$thetaLowess){lines(lowess(thetas.plot$WinCenter,data, f=0.1), col="red")}
      }
      else {
        plot(thetas.plot$WinCenter,
             data, t="p", pch=19,col=rgb(0,0,0,0.5),
             xlab="Position (bp)",
             ylab=paste(input$thetaChoice,"Estimator Value"),
             main=paste("Estimators of theta along chromosome", thetas$Chr[1])
        )
        if(input$thetaLowess){lines(lowess(thetas.plot$WinCenter,data, f=0.1), col="red")}
      }
    })

    output$selectionPlot <- renderPlot({
      # error handling code to provide a default dataset to graph
      thetas <- tryCatch({
        dataInputThetas()
      }, error = function(err) {
        thetas <- read.table(file="BKN_Diversity.thetas.gz.pestPG",
                             sep="\t",
                             col.names=thetas.headers
        )
      }
      )


      thetas <- subset(thetas,Chr==input$thetaChrom)

      if(input$subset) {
        thetas.plot <- subset(thetas, WinCenter > input$WinCenterLow & WinCenter < input$WinCenterHigh)
      }
      else {
        thetas.plot <- thetas
      }

      # remove nsites=0
      thetas.plot <- subset(thetas.plot, nSites != 0)

      data <- switch(input$selectionChoice,
                     "Tajima's D" = thetas.plot$Tajima,
                     "Fu and Li's F" = thetas.plot$fuf,
                     "Fu and Li's D" = thetas.plot$fud,
                     "Fay and Wu's H" = thetas.plot$fayh,
                     "Zeng's E" = thetas.plot$zeng
      )
      
      plot(thetas.plot$WinCenter,
           data, t="p", pch=19,col=rgb(0,0,0,0.5),
           xlab="Position (bp)",
           ylab=input$selectionChoice,
           main=paste("Neutrality test statistics along chromosome", thetas$Chr[1])
      )
      if(input$selectionLowess){lines(lowess(thetas.plot$WinCenter,data, f=0.1), col="red")}
    })

    output$fstChroms = renderUI({
      if(is.null(input$userIntersect)){
        choices <- 12
      }
      else{
        intersect <- dataInputIntersect()
        choices <- unique(intersect$Chr)
      }
      selectInput('fstChrom', 'Chromosome to plot', choices)
    })

    output$fstMin = renderUI({
      if(is.null(input$userIntersect)){
        min <- 10944
        max <- 27530233
      }
      else{
        intersect <- dataInputIntersect()
        min <- min(intersect$bp)
        max <- max(intersect$bp)
      }
      numericInput("intersectLow", "Base Start Position", value=min, min = min, max=max-1)
    })

    output$fstMax = renderUI({
      if(is.null(input$userIntersect)){
        min <- 10944
        max <- 27530233
      }
      else{
        intersect <- dataInputIntersect()
        min <- min(intersect$bp)
        max <- max(intersect$bp)
      }
      numericInput("intersectHigh", "Base Start Position", value=min+10000, min=min+1, max=max)
    })

    output$fstPlot <- renderPlot({
      #error handling code to provide a default dataset to graph
      fst <- tryCatch({
        dataInputFst()
      }, error = function(err) {
        fst <- fread("allo.indica.fst",
                             sep="\t")
      })
      intersect <- tryCatch({
        dataInputIntersect()
      }, error = function(err) {
        intersect <- fread("intersect.allo.indica_intergenic.txt",
                        sep="\t")
      })
      setnames(fst,fst.headers)
      setnames(intersect,intersect.headers)
      fst.intersect <- cbind(intersect,fst)
      fst.intersect <- subset(fst.intersect, Chr==input$fstChrom)
      fst.intersect <- subset(fst.intersect, FST>=0 & FST<=1)

      if(input$annotations){
        validate(need(input$userAnnotations, 'Need GFF file before clicking checkbox!'))
        gff <- gffInput()
        gff.gene <- subset(gff, type="gene")
        gff.df <- data.frame(gff.gene,annotation(gff))
        gff.df.gene <- subset(gff.df, type=="gene")
      }

      if(input$subset) {
        fst.plot <- subset(fst.intersect, bp >= input$intersectLow & bp <= input$intersectHigh)
      }
      else {
        fst.plot <- fst.intersect
      }

      if(input$annotations) {
        plot(fst.plot$bp,
             fst.plot$FST, t="p", pch=19,col=rgb(0,0,0,0.5),
             xlab="Position (bp)",
             ylab="Fst",
             main=paste("Fst along chromosome")
        )
        rug(rect(gff.df.gene$X1, -1e2, gff.df.gene$X2, 0, col=rgb(0.18,0.55,0.8,0.75), border=NA))
        if(input$fstLowess){lines(lowess(fst.plot$bp,fst.plot$FST, f=0.1), col="red")}
      }
      else {
        plot(fst.plot$bp,
             fst.plot$FST, t="p", pch=19,col=rgb(0,0,0,0.5),
             xlab="Position (bp)",
             ylab=paste("Fst"),
             main=paste("Fst along chromosome", fst.plot$Chr[1])
        )
        if(input$fstLowess){lines(lowess(fst.plot$bp,fst.plot$FST, f=0.1), col="red")}
      }
    })

    output$SFSPlot <- renderPlot({
      sfs <- tryCatch({
        dataInputSFS()

      },error = function(err) {
        sfs <- exp(scan("sfs_example.txt"))
      })
      subsfs <- sfs[-c(1,length(sfs))]/sum(sfs[-c(1,length(sfs))])
      barplot(subsfs, xlab="Chromosomes", ylab="Proportion", main="Site Frequency Spectrum",names=1:length(sfs[-c(1,length(sfs))]), col="#A2C8EC", border=NA)

    })

    output$admixPlot <- renderPlot({
      admix <- tryCatch({
        dataInputAdmix()

      },error = function(err) {
        admix<-t(as.matrix(read.table("ngsadmix_example.txt")))
      })
      barplot(admix,col=c("#006BA4","#FF800E","#A2C8EC","#898989","#ABABAB","#595959","#5F9ED1","#CFCFCF","#FFBC79","#C85200"),space=0,border=NA,xlab="Individuals",ylab="admixture proportion")

    })

    output$ABBABABATree <- renderPlot({
      ABBABABA <- tryCatch({
        dataInputABBABABA()
      }, error = function(err){
        ABBABABA <- read.table("abbababa.test", sep="\t", header=T)
      })
      d.current <- subset(ABBABABA, H2 == input$h2 & H3 == input$h3)
      tree <- read.tree(text=paste("(Outgroup,(", input$h3, ",(", input$h2, ",Taxon)));", sep=""))
      plot(tree, type = "cladogram", edge.width = 2, direction='downwards')

    })
    output$ABBABABAPlot <- renderPlot({
      ABBABABA <- tryCatch({
        dataInputABBABABA()
      }, error = function(err){
        ABBABABA <- read.table("abbababa.test", sep="\t", header=T)
      })
      d.current <- subset(ABBABABA, H2 == input$h2 & H3 == input$h3)
      mypanel.Dotplot <- function(x, y, ...) {
        panel.Dotplot(x,y,...)
        tips <- attr(x, "other")
        panel.abline(v=0, lty=3)
        trellis.par.set(mfrow=c(2,1))
        panel.arrows(x0 = tips[,1], y0 = y,
                     x1 = tips[,2], y1 = y,
                     length = 0.05, unit = "native",
                     angle = 90, code = 3)
      }
      Dotplot(factor(d.current$H1) ~ Cbind(d.current$Dstat,d.current$Dstat-d.current$SE,d.current$Dstat+d.current$SE), col="blue", pch=20, panel = mypanel.Dotplot,
              xlab="D",ylab="Taxon", title=paste("D statistic comparison where H2=", input$h2, " and H3=", input$h3, sep=""))

    })

    output$PCAPlot <- renderPlot({
      PCA <- tryCatch({
        dataInputPCA()

      },error = function(err) {
        PCA <- read.table("all.pop.covar", header=F)
      })
      eig <- eigen(PCA, symm=TRUE);
      eig$val <- eig$val/sum(eig$val);
      PC <- as.data.frame(eig$vectors)
      plot(PC$V1, PC$V2, pch=19, col=rgb(0,0,0,0.4),xlab="PC1", ylab="PC2", main="ngsCovar Results",asp=1)
    })

    output$pacBio <- renderText({
      if(input$fastaChoice=='Yes'){
        text <- "Glad to hear it!"
      }
      if(input$fastaChoice=='No'){
        text <- "Perhaps your reads are too short. Have you considered PacBio?"
      }
      return(text)
    })
  })
