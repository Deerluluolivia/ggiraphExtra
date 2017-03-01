#'Clean theme for PieDonut plot
#'@param base_size An interger, default 12.
#'@importFrom ggplot2 theme_grey %+replace%
#'@importFrom grid unit
#'@export
theme_clean=function(base_size=12){
        theme_grey(base_size) %+replace%
                theme(
                        axis.title=element_blank(),
                        axis.text=element_blank(),
                        panel.background=element_blank(),
                        panel.grid=element_blank(),
                        axis.ticks.length=unit(0,"cm"),
                        axis.ticks.margin=unit(0,"cm"),
                        panel.margin=unit(0,"lines"),
                        plot.margin=unit(c(0,0,0,0),"lines"),
                        complete=TRUE
                )
}
#'Computing breaks for make a histogram of a continuous variable
#'
#'@param x A continuous variables
#'@export
#'@return A list contains a factor and a numeric vector
#'
num2cut=function(x){
        breaks=list()
        breaks <- c(list(x = x), breaks)
        breaks <- list(x = x)
        breaks$plot <- FALSE
        breaks <- do.call("hist", breaks)$breaks
        x1 <- cut(x, breaks = breaks, include.lowest = TRUE)
        result=list(x1=x1,breaks=breaks)
        result
}


#'Draw an interactive spinogram
#'
#'@param data A data.frame
#'@param mapping Set of aesthetic mappings created by aes or aes_.
#'@param stat The statistical transformation to use on the data for this layer, as a string
#'            c("count","identity")
#'@param position Position adjustment. One of the c("fill","stack","dodge")
#'@param palette A character string indicating the color palette
#'@param interactive A logical value. If TRUE, an interactive plot will be returned
#'@param polar A logical value. If TRUE, coord_polar() function will be added
#'@param reverse If true, reverse palette colors
#'@param width Bar width
#'@param digits integer indicating the number of decimal places
#'@param colour Bar colour
#'@param size Bar size
#'@param addlabel A logical value. If TRUE, label will be added to the plot
#'@param hide.legend A logical value. If TRUE, the legend is removed and y labels are recreated
#'@param ... other arguments passed on to geom_rect_interactive.
#'@importFrom ggplot2 coord_polar scale_y_continuous guide_legend
#'@importFrom ggiraph geom_rect_interactive
#'@export
#'@return An interactive spinogram
#'@examples
#'require(moonBook)
#'require(ggplot2)
#'require(ggiraph)
#'ggSpine(data=acs,aes(x=age,fill=sex),interactive=TRUE)
#'ggSpine(data=acs,aes(x=sex,fill=Dx),addlabel=TRUE,interactive=TRUE)
#'ggSpine(data=acs,aes(x=Dx,fill=smoking),position="dodge",addlabel=TRUE,interactive=TRUE)
#'ggSpine(data=acs,aes(x=Dx,fill=smoking),position="stack",addlabel=TRUE,interactive=TRUE)
ggSpine=function (data, mapping, stat = "count", position = "fill", palette = "Blues",
                  interactive = FALSE, polar = FALSE, reverse = FALSE, width = NULL,
                  digits = 1, colour = "black", size = 0.2, addlabel = FALSE, hide.legend=FALSE,
                  ...)
{
        # data=subset(final,DES_NO>0);mapping=aes(x=rank2,fill=DES_NO)

        # data=acs;mapping=aes(x=Dx,fill=smoking)
        # stat = "identity"; position = "fill"; palette = "Blues"
        # interactive = FALSE; polar = FALSE; reverse = FALSE; width = NULL;
        # digits = 1; colour = "black"; size = 0.2; addlabel = FALSE

        xvar <- fillvar <- facetvar <- yvar <- NULL
        if ("x" %in% names(mapping))
                xvar <- paste(mapping[["x"]])
        if ("y" %in% names(mapping))
                yvar <- paste(mapping[["y"]])
        if ("fill" %in% names(mapping))
                fillvar <- paste(mapping[["fill"]])
        if ("facet" %in% names(mapping))
                facetvar <- paste(mapping[["facet"]])
        contmode = 0
        if (is.numeric(data[[xvar]])) {
                if (is.null(width)) width = 1
                width
                result = num2cut(data[[xvar]])
                b = result$x1
                breaks = result$breaks
                a = table(data[[fillvar]], b)
                a
                df = reshape2::melt(a)
                df = df[c(2, 1, 3)]
                colnames(df) = c(xvar, fillvar, "nrow")
                df
                contmode = 1
        } else if ((stat == "identity") & (!is.null(yvar))) {
                df = data[c(xvar, fillvar, yvar)]
                df =df[order(df[[xvar]],df[[fillvar]]),]
                colnames(df)[3] = "nrow"
                myformula = as.formula(paste(fillvar, "~", xvar))
                myformula
                b = reshape2::dcast(df, myformula, value = nrow)
                b
                a = b[, -1]
                rownames(a) = b[[1]]
                a = as.matrix(a)
                a
        } else {
                df = plyr::ddply(data, c(xvar, fillvar), "nrow",.drop=FALSE)
                a = table(data[[fillvar]], data[[xvar]])
        }
        df
        if (is.null(width)) width = 0.9
        #(df$xno = as.numeric(factor(df[[1]])))

        a
        nrow(a)
        df
        df$xno=rep(1:(nrow(df)/nrow(a)),each=nrow(a))
        (df$yno = as.numeric(factor(df[[2]])))
        (total = sum(a))
        (csum = colSums(a))
        (rsum = rowSums(a))
        (xmax = cumsum(csum))
        (xmin = cumsum(csum) - csum)
        (x = (xmax + xmin)/2)
        (width = csum * width)
        (xmax = x + width/2)
        (xmin = x - width/2)
        df$xmin = df$xmax = df$x = df$csum = df$width = 0
        df$xno
        nrow(df)
        df

        df$csum = rep(csum,each=nrow(a))
        df$xmin = rep(xmin,each=nrow(a))
        df$xmax = rep(xmax,each=nrow(a))
        df$x = rep(x,each=nrow(a))
        df$width = rep(width,each=nrow(a))
        count = max(df$xno)
        df
        if (position == "dodge") {
                df$ymax = df$nrow
                df$ymin = 0
                df$y = (df$ymax + df$ymin)/2
                ycount = max(df$yno)
                df$xmin2 = df$xmin + (df$yno - 1) * (df$width/ycount)
                df$xmax2 = df$xmin2 + (df$width/ycount)
                df$xmin = df$xmin2
                df$xmax = df$xmax2
                df$x = (df$xmax + df$xmin)/2
                df2 = df
        } else {
                for (i in 1:count) {
                        dfsub = df[df$xno == i, ]
                        dfsub$ratio = round(dfsub$nrow * 100/csum[i], digits)
                        dfsub$ymax = cumsum(dfsub$nrow)
                        dfsub$ymin = dfsub$ymax - dfsub$nrow
                        if (position == "fill") {
                                dfsub$ymax = dfsub$ymax * 100/csum[i]
                                dfsub$ymin = dfsub$ymin * 100/csum[i]
                        }
                        dfsub$y = (dfsub$ymin + dfsub$ymax)/2
                        if (i == 1)
                                df2 = dfsub
                        else df2 = rbind(df2, dfsub)
                }
        }
        df2$data_id = as.character(1:nrow(df2))
        df2$tooltip = paste0(df2[[xvar]], "<br>", df2[[fillvar]],
                             "<br>", df2$nrow)
        df2$label = ifelse((df2$csum/total) > 0.04, df2$nrow, "")
        df2$tooltip = paste0(df2$tooltip, "(", df2$ratio, "%)")
        if (position == "fill") {
                df2$label = ifelse((df2$csum/total) > 0.04, paste0(df2$ratio,
                                                                   "%"), "")
        }
        if (contmode) {
                xlabels = breaks[2:length(breaks)]
                xlabels
                xlabels[csum/total < 0.04] = ""
        } else xlabels = levels(factor(df[[1]]))
        ylabels = levels(factor(df[[2]]))
        if (contmode) {
                ycount = length(ylabels)
                (pos = 1:ycount)
                y = (100/ycount) * (pos - 1) + (100/ycount)/2
        } else y = df2[df2$xno == 1, "y"]
        y
        ylabels
        df2
        if (is.numeric(df2[[fillvar]]))
                df2[[fillvar]] = factor(df2[[fillvar]])
        p <- ggplot(mapping = aes_string(xmin = "xmin", xmax = "xmax",
                                         ymin = "ymin", ymax = "ymax", fill = fillvar), data = df2) +
                geom_rect_interactive(aes_string(tooltip = "tooltip",
                                                 data_id = "data_id"), size = size, colour = colour,...) + xlab(xvar)

        p
        if (contmode) {
                p <- p + scale_x_continuous(breaks = xmax, labels = xlabels,
                                            limits = c(0, total))
        }else {
                p <- p + scale_x_continuous(breaks = x, labels = xlabels,
                                            limits = c(0, total))
        }
        p
        direction = ifelse(reverse, -1, 1)

        if ((position != "dodge") & hide.legend ){
                p <- p + scale_y_continuous(breaks = y, labels = ylabels) +
                        scale_fill_brewer(palette = palette, direction = direction,
                                          guide = FALSE) + ylab("")
        }
        else{
                p <- p + ylab("count")+guides(fill=guide_legend(reverse=TRUE))

                p <- p + scale_fill_brewer(palette = palette,
                                   direction = direction)
        }
        if (addlabel)
                p = p + geom_text(aes(x = x, y = y, label = df2$label))
        p <- p + theme_bw() + theme(axis.text.y = element_text(angle = 90),
                                    axis.ticks.y = element_blank())
        if (polar == TRUE)
                p <- p + coord_polar()
        tooltip_css <- "background-color:white;font-style:italic;padding:10px;border-radius:10px 20px 10px 20px;"
        hover_css = "fill-opacity=.3;cursor:pointer;stroke:gold;"
        if (interactive)
                p <- ggiraph(code = print(p), tooltip_extra_css = tooltip_css,
                             tooltip_opacity = 0.75, zoom_max = 10, hover_css = hover_css)
        p
}