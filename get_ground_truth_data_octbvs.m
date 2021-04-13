%% MATLAB SCRIPT TO VIEW DATA AND GROUND TRUTH

%% directory to view (SET THIS TO THE APPROPRIATE DIRECTORY PATH!)   
SEQ_DIR = '00010';


%%--------------------------------------------------



%% grab the ground truth file
filename = fullfile(SEQ_DIR, 'groundTruth.txt');
fid = fopen(filename);

%% read file comments
line = fgets(fid);
while line(1) == '%'
    line = fgets(fid);
end

%% read number of images
numImages = sscanf(line, '%d', 1);

%% view each image
for i=1:numImages
    
    %% get image name
    imageName = fscanf(fid, '%c',13);

    %% get number of boxes
    numBoxes = fscanf(fid, '%d', 1);

    %% get the boxes
    for j=1:numBoxes
        tmp = fscanf(fid, '%c',2); %% [space](
        coords = fscanf(fid, '%d %d %d %d');
        tmp = fscanf(fid, '%c',1); %% )
        ulX=coords(1); ulY=coords(2);
        lrX=coords(3); lrY=coords(4);
        boxes{j}.X = [ulX lrX lrX ulX ulX]';
        boxes{j}.Y = [ulY ulY lrY lrY ulY]';
    end 
    tmp = fgetl(fid); %% get until end of line
        
    %% load and display the image
    fname = fullfile(SEQ_DIR, imageName);
    Im = imread(fname);
    imagesc(Im);
    colormap('gray');
    axis('off');
    title(sprintf('Image %d', i));
    hold on;
    
    %% display the boxes
    for j=1:numBoxes
        plot(boxes{j}.X, boxes{j}.Y, 'y');
    end
    
    %% wait briefly
    pause(1);
    hold off;
    clear Im;

end

%% close file
fclose(fid);
disp('[DONE]');

return;