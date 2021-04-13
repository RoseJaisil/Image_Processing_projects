%example segmentation of otcbvs images

close all;
clear all;

%path = 'C:\Users\mroggema\work\ee5532\octbvs_data\00001\00001\';
%path = 'H:\ee5532\spring2020\lecture3\'
path = 'G:\OCTBVS_data\00001\00001\';

%img1 = double(imread([path,'img_00002.bmp']));
img1 = double(imread([path,'img_00010.bmp']));

figure
imagesc(img1)
axis('image')
title('otcbvs image2')
colormap(gray(256))

[rlen,clen] = size(img1)

maximg1 = max(max(img1))
minimg1 = min(min(img1))

ngraylevels = maximg1 - minimg1 + 1;
graylevelvec = minimg1:maximg1;

[N,EDGES] = histcounts(img1,ngraylevels);

figure
plot(graylevelvec,N)
xlabel('gray level')
ylabel('number of pixels')

%test threshold
thresh = 110;
[rlist,clist] = find(img1 >= thresh);

threshimg1 = zeros(rlen,clen);
for m=1:length(rlist)
    threshimg1(rlist(m),clist(m)) = 1;
end;

figure
imagesc(threshimg1)
axis('image')
title('threshold image')

%label the regions that survive thresholding
[label_img,num_regions] = bwlabel(threshimg1,4);

figure
imagesc(label_img)
axis('image')
title(['labeled image, number of regions = ', num2str(num_regions)])
colorbar('EastOutside')

%first test - extract and remove regions that are too small
pixelcnt_thresh = 10;
intermediate_img1 = zeros(rlen,clen);   %array to hold the image with small regions removed
for m=1:num_regions
    [rl,cl] = find(label_img == m);  %rl and cl are vectors holding locations of pixels with label m
    
    if length(rl) >= pixelcnt_thresh   %only turn on regions that are "big enough"
        for n=1:length(rl)
            intermediate_img(rl(n),cl(n)) = 1;
        end;
    end;
 
end;

figure
imagesc(intermediate_img)
axis('image')
title('image after removing small regions')

%create structuring element for dilation and erosion
SEdilate = strel('square',5);

SEdilate.Neighborhood

dilated_img = imdilate(intermediate_img,SEdilate);

figure
imagesc(dilated_img)
axis('image')
title('after dilation')

%now erode
SEerode = strel('square',2);

SEerode.Neighborhood

eroded_img = imerode(dilated_img,SEdilate);

figure
imagesc(eroded_img)
axis('image')
title('after erosion')

%demonstrate pulling regions out and computing features
%label the regions that survive thresholding
[label_img,num_regions] = bwlabel(eroded_img,4);

['number of regions segmented = ', num2str(num_regions)]

%find bounding box of each segmented region
ulc_row = zeros(num_regions,1);
ulc_col = zeros(num_regions,1);
lrc_row = zeros(num_regions,1);
lrc_col = zeros(num_regions,1);
middle_row = zeros(num_regions,1);
middle_col = zeros(num_regions,1);
nrow_blob = zeros(num_regions,1);
ncol_blob = zeros(num_regions,1);

figure;
imagesc(label_img)
axis('image')
title('segmented, labeled image with region indices displayed')
for m=1:num_regions
    [rlist,clist] = find(label_img == m);
    
    ulc_row(m) = min(rlist);
    ulc_col(m) = min(clist);
    lrc_row(m) = max(rlist);
    lrc_col(m) = max(clist);

    nrow_blob(m) = lrc_row(m) - ulc_row(m) + 1;
    ncol_blob(m) = lrc_col(m) - ulc_col(m) + 1;
    
    middle_row(m) = round((ulc_row(m) + lrc_row(m))/2);
    middle_col(m) = round((ulc_col(m) + lrc_col(m))/2);
    
    text(middle_col(m),middle_row(m),['region ',num2str(m)]);
    
end;

%pull regions out one at a time and display
%also compute height-to-width ratio
h_2_w_ratio = zeros(num_regions,1);
for m=1:num_regions
    [rlist,clist] = find(label_img == m);
    
    blob = zeros(nrow_blob(m),ncol_blob(m));
    for q=1:length(rlist)    
    
        rblob = rlist(q) - ulc_row(m) + 1;
        cblob = clist(q) - ulc_col(m) + 1;
        
        blob(rblob,cblob) = img1(rlist(q),clist(q));
        
    end;
    
    h_2_w_ratio(m) = nrow_blob(m)/ncol_blob(m);   %your first feature
    
    figure
    imagesc(blob)
    axis('image')
    colormap(gray(256))
    title(['blob = ', num2str(m),' h/w ratio = ',num2str(h_2_w_ratio(m))])
    
end;


    
    