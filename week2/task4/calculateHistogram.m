function [aColorHistogram bColorHistogram] = calculateHistogram(image, mask, boundingBox, nBins)
%{
Jonatan Poveda
Martí Cobos
Juan Francesc Serracant
Ferran Pérez
Master in Computer Vision
Computer Vision Center, Barcelona
---------------------------
Project M1/Block2
---------------------------
This function is used to compute the image color histogram.
input:  - image:  nxmx3 array representing image to be analyzed
        - mask: nxm array representing image mask
        - boundingBox: mask bounding box coordinates (TopLeftY, TopLeftX, BottomRightY, BottomRightX)
output: - histogram: image color histogram
---------------------------
%}

    close all;
    % Modify mask inorder to avoid errors when masks are not well defined
    mask(mask>0)=1;
    image_lab = rgb2lab(image);
    a= image_lab(:,:,2);
    b= image_lab(:,:,3);

    % Analyze Bounding box
    topLeftY = boundingBox(1);
    topLeftX = boundingBox(2);
    bottomRightY = boundingBox(3);
    bottomRightX = boundingBox(4);

    % Modify mask in order to only accept values inside the BB
    BBmask = zeros (size(a));
    BBmask(int32(topLeftY):int32(bottomRightY),int32(topLeftX):int32((bottomRightX))) = 1;
    mask(BBmask ==0)=0;

    % Compute color histograms for a and b chromacity coordinates
    counts = linspace(-100,100,nBins+1);

    % To take account the bin size use the next two lines
    %colorHistogram = histogram(a(mask==1),counts,'Normalization','pdf');
    %colorHistogram = histogram(b(mask==1),counts,'Normalization','pdf');
    colorHistogram = histogram(a(mask==1),counts,'Normalization','probability');
    colorHistogram = histogram(b(mask==1),counts,'Normalization','probability');

    aColorHistogram = colorHistogram.Values;
    bColorHistogram = colorHistogram.Values;
end
