#colgrad<<-c(colorRampPalette(c("white",colors()[378],"orange", "tomato","mediumorchid4"))(100))
#sample_cols<<-rep(paste("#",read.table("sample_colors.txt",stringsAsFactors = F)[,1],sep=""),10)

plot_avg_heatmap=function(m,zlim,main_title,genes,gene.cols,clusters,clusters_text,annots,Relative_or_Absolute="Relative",colgrad,reg,cex.genes=1,cex.clusters=1,line.genes=1){
  if (Relative_or_Absolute=="Relative"){
    if (ncol(m)>1){
      m=log2((reg+m)/pmax(reg,rowMeans(m,na.rm=T)))
    }
    else{
      return()
    }
  }
  else if (Relative_or_Absolute=="Absolute"){
    m=log10(reg+m)
  }
  else{
    plot.new()
    return()
  }
  break1=min(m,na.rm=T)
  break2=max(m,na.rm=T)

  breaks=sort(c(break1,seq(zlim[1],zlim[2],l=99),break2))
  
  image(m[,ncol(m):1],col=colgrad,breaks=breaks,axes=F,main=main_title)
  box()
  mtext(text = genes,side = 1,at = seq(0,1,l=length(genes)),las=2,cex=cex.genes,col=gene.cols,line=line.genes)
  mtext(text =paste(" ",clusters,clusters_text), side=4, at=seq(1,0,l=length(clusters)),las=2,cex=cex.clusters)
  mtext(text =paste(annots," ",sep=""), side=2, at=seq(1,0,l=length(annots)),las=2,cex=cex.clusters)
}

plot_avg_heatmap_interactive=function(m,zlim,main_title,genes,gene.cols,clusters,clusters_text,annots,Relative_or_Absolute="Relative",colgrad){
  if (Relative_or_Absolute=="Relative"){
    if (ncol(m)>1){
      m=log2(1e-6+m/pmax(1e-6,rowMeans(m,na.rm=T)))
    }
    else{
      return()
    }
  }
  else if (Relative_or_Absolute=="Absolute"){
    m=log10(1e-6+m)
  }
  else{
    plot.new()
    return()
  }
  break1=min(m,na.rm=T)
  break2=max(m,na.rm=T)
  
  m[m<zlim[1]]=zlim[1]
  m[m>zlim[2]]=zlim[2]

  version_vector=unlist(packageVersion("heatmaply"))
  clusters_vec=colnames(m)
  if (version_vector[1]==0&&version_vector[2]<15){
    clusters_vec=rev(clusters_vec)
    annots=rev(annots)
  }
    
  heatmaply(t(m),Rowv=F,Colv=F, scale = "none", colors = colgrad,hide_colorbar=T,label_names=c("Cluster","Gene","Value"),labRow=paste(annots," (",clusters_vec,")",sep=""),labCol=rownames(m),main_title=main_title,column_text_angle=90,margins =c(100,180,20,0),fontsize_row = 8,fontsize_col = 8)
  
}




plot_truth_heatmap=function(ds,cell_to_sample,cell_to_cluster,insamples,ingenes,inclusts,zlim,cols=colgrad,sample_cols=NULL,showSeparatorBars=T,seperatorBars_lwd=1,plot_batch_bar=T,gene_text_cex=1,cluster_text_cex=1,lower_mar=10,showClusterLabels=T,score_genes=NULL,reverse_score_order=F,global_order=F){

  
  ds=ds[ingenes,cell_to_cluster[colnames(ds)]%in%inclusts]
  score_genes=intersect(score_genes,rownames(ds))
  if ((!is.null(score_genes))&(length(score_genes)>=1)){
    score_rank=rank(apply(log2(.1+as.matrix(ds[score_genes,,drop=F])),2,mean))/ncol(ds)
    
    if (reverse_score_order){
      score_rank=1-score_rank
    }
    cell_ord=order((1-global_order)*2*match(cell_to_cluster[colnames(ds)],inclusts)+score_rank)
    if (global_order){
      showSeparatorBars=F
      showClusterLabels=F
    }
  }else{
    cell_ord=order(match(cell_to_sample[colnames(ds)],insamples)+length(insamples)*match(cell_to_cluster[colnames(ds)],inclusts))
  }
  
  
  
  ds=ds[,cell_ord]
  samps=cell_to_sample[colnames(ds)]
  ncells=rep(0,length(inclusts))
  names(ncells)=inclusts
  tmp_ncells=sapply(split(colnames(ds),cell_to_cluster[colnames(ds)]),length)
  ncells[names(tmp_ncells)]=tmp_ncells
  
  if (is.null(sample_cols)){
    sample_cols=1:length(unique(samps))  
  } 
  pmat=as.matrix(ds)[,ncol(ds):1]
  spacer_size=ceiling(dim(pmat)[2]/200)
  pmat2=log2(1+pmat)
  if (plot_batch_bar){
    layout(matrix(1:2,1,2),widths=c(40,1))
  }
  par(mar=c(lower_mar,3,1,1))
  image(pmat2,col=c("gray",cols),axes=F,breaks=c(-3e6,-1e6,seq(zlim[1],zlim[2],l=99),1e6))
  
  box()
  if (showSeparatorBars){
    abline(h=1-cumsum(ncells)/sum(ncells),col="gray",lwd=seperatorBars_lwd)
  }
  mtext(text =rownames(pmat), side=1, at=seq(0,1,l=dim(pmat)[1]),las=2,cex=gene_text_cex,adj=1,line=1)
  a=cumsum(ncells)
  b=a-floor(ncells[inclusts[inclusts%in%names(ncells)]]/2)
  if (showClusterLabels){
    mtext(text =inclusts, side=2, at=1-(b/a[length(ncells)]),las=2,cex=cluster_text_cex,adj=1,line=.2)
  }
  if (plot_batch_bar){
    par(mar=c(lower_mar,0,1,1))
    image(t(as.matrix(match(rev(samps),insamples))),axes=F,breaks=0:length(insamples)+.5,col=sample_cols[1:length(insamples)])
    mtext("Samples",side=1,las=2,line=1,cex=gene_text_cex*1.2)
  }
}
