close all;
clear all;

% Read and display image 
img1 = double(imread('Test set/img_00001.bmp'));
img2 = mat2gray(img1);
figure
imagesc(img2)
axis('image')
title('Input image2')
colormap(gray(256))

% Generating histogram
[rlen,clen] = size(img1);
maximg1 = max(max(img1));
minimg1 = min(min(img1));
ngraylevels = maximg1 - minimg1 + 1;
graylevelvec = minimg1:maximg1;
[N,EDGES] = histcounts(img1,ngraylevels);
figure
plot(graylevelvec,N)
xlabel('gray level')
ylabel('number of pixels')

%test threshold based on where the peak in the histogram settles down.
thresh = 156; %156 for the train images
[rlist,clist] = find(img1 >= thresh);
threshimg1 = zeros(rlen,clen);
for m=1:length(rlist)
    threshimg1(rlist(m),clist(m)) = 1;
end
figure
imagesc(threshimg1)
axis('image')
title('threshold image')

% label the image to get the individual objects
[label_img1,num_regions] = bwlabel(threshimg1,4);
figure;
imagesc(label_img1)
axis('image')
title('labeled image showing differnt regions')

% removing objects of small area
pixelcnt_thresh = 20;
intermediate_img1 = zeros(rlen,clen);   %array to hold the image with small regions removed
for m=1:num_regions
    [rl,cl] = find(label_img1 == m);  %rl and cl are vectors holding locations of pixels with label m
  
    if length(rl) >= pixelcnt_thresh   %only turn on regions that are "big enough"
        for n=1:length(rl)
            intermediate_img1(rl(n),cl(n)) = 1;
        end;
    end;
end;
figure
imagesc(intermediate_img1)
axis('image')
title('image after removing small regions')

% imclose
SE = strel('square',7);
intermediate_img2 = imclose(intermediate_img1,SE);
figure;
imagesc(intermediate_img2);
axis('image')
title('Closed image');

% filter according to the area
[label_img2,num_regions] = bwlabel(intermediate_img2,4);

%find bounding box of each segmented region 
% We will segment the image based on the height width ratio
ulc_row = zeros(num_regions,1);
ulc_col = zeros(num_regions,1);
lrc_row = zeros(num_regions,1);
lrc_col = zeros(num_regions,1);
middle_row = zeros(num_regions,1);
middle_col = zeros(num_regions,1);
nrow_blob = zeros(num_regions,1);
ncol_blob = zeros(num_regions,1);
h_2_w_ratio = zeros(num_regions,1);
bw2 = label_img2;
for m=1:num_regions
    [rlist,clist] = find(label_img2 == m);
  
    ulc_row(m) = min(rlist);
    ulc_col(m) = min(clist);
    lrc_row(m) = max(rlist);
    lrc_col(m) = max(clist);
    nrow_blob(m) = lrc_row(m) - ulc_row(m) + 1;
    ncol_blob(m) = lrc_col(m) - ulc_col(m) + 1;
    h_2_w_ratio(m) = nrow_blob(m)/ncol_blob(m); 
    if h_2_w_ratio(m)<1.1
        bw2(label_img2 == m)=false; % this step is for filtering objects in an image based on the height and width ratio
    end
    middle_row(m) = round((ulc_row(m) + lrc_row(m))/2);
    middle_col(m) = round((ulc_col(m) + lrc_col(m))/2);
  
    text(middle_col(m),middle_row(m),['region ',num2str(m)]);
   
end;

% again labeing the image after filtering
[label_img3,num_regions] = bwlabel(bw2,4);
figure;
imagesc(label_img3);
axis('image')
title('Labeled after filtering');

% some small structures escaped our
% again area filtering to eliminate smaller items
bw = imbinarize(label_img3);
area_filt = bwareafilt(bw, [60 1000]);
figure
imshow(area_filt)
axis('image')
title('Area filtered image')

% one last time for the area filtering to hadle the sticky objects
newbw = bwareafilt(area_filt, [250 5000]);
% Tried watershed method, for loop erosion and dilation 
% to seperate the sticky objetcs
if bwconncomp(newbw,4).NumObjects~=0
remaining = area_filt-newbw;
% method 1
figure;
imshow(newbw,[]);
axis('image')
title('Sticky objects to seperate');

% So we mask again
final = newbw.*img1;
g = final>145;
figure
imshow(g,[]);
axis('image')
title('Thresholded sticky objects');

% Erode to seperate
SE = strel('rectangle',[6 3]);
g = imopen(g,SE);

% if bwconncomp(g,4).NumObjects>2 % If they are oversegeregated
% g = imdilate(g,strel('rectangle',[4 1]));
% figure;imshow(g)
% title('Segregated image threshold');
% else
figure
axis('image')
imshow(g,[])
title('Segregated image threshold');
% end
% Combine all the objects

% % method 2: Watershed segmentation
% revim = imcomplement(newbw);
% imshow(revim,[])
% D = bwdist(revim);
% D2 = imcomplement(D);
% imshow(D2,[])
% % Suppress shallow minima
% D3 = imhmin(D2,1);
% L = watershed(D3);
% newbw(L == 0) = 0;
% imshow(newbw)
% g =newbw


area_filt = g + remaining;
end

[final_label,n]=bwlabel(area_filt);
for m=1:n
[rlist,clist] = find(final_label == m);

ulc_row(m) = min(rlist);
ulc_col(m) = min(clist);
lrc_row(m) = max(rlist);
lrc_col(m) = max(clist);
nrow_blob(m) = lrc_row(m) - ulc_row(m) + 1;
ncol_blob(m) = lrc_col(m) - ulc_col(m) + 1;
middle_row(m) = round((ulc_row(m) + lrc_row(m))/2);
middle_col(m) = round((ulc_col(m) + lrc_col(m))/2);
blob = zeros(nrow_blob(m),ncol_blob(m));
for q=1:length(rlist)    
rblob = rlist(q) - ulc_row(m) + 1;
cblob = clist(q) - ulc_col(m) + 1;
blob(rblob,cblob) = img1(rlist(q),clist(q));        
end;
h_2_w_ratio1(m) = nrow_blob(m)/ncol_blob(m);   %height and width ratio
figure
imagesc(blob)
axis('image')
colormap(gray(256))

title(['blob = ', num2str(m),' h/w ratio = ',num2str(h_2_w_ratio1(m))])    

text(middle_col(m),middle_row(m),['region ',num2str(m)]);

end;

%masking by mutliplying for visualizing the images
masked_img = img1.*area_filt;
figure;
imshow(masked_img,[]);
axis('image')
title('Masked image');

% images are shown with the bounding box
figure;
imshow(img2,[]);
axis('image')
title('Resultant segmented image with bounding box');
measurements = regionprops(final_label, 'BoundingBox', 'Area');
for k = 1 : length(measurements)
BB = measurements(k).BoundingBox;
rectangle('Position', [BB(1),BB(2),BB(3),BB(4)],...
'EdgeColor','r','LineWidth',2 )
end