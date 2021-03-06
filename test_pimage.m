%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% PROBABILITY IMAGE %%
%%%%%%%%%%%%%%%%%%%%%%%%%

load('test\pimage_testdata_new_FN002_lombard.mat');

% shape: Binary image. Glottis are zeros, the rest are ones
% border: coordinates of the border; (x,y)
% roimask: Binary image. ROI are ones
% idxlow: Index of lowest border point in image. Since the axis is
%         inverted, it has the highest 'y' coordinate. idxhigh is the
%         opposite.

% Calcular histograma 3d para 8 puntos en el borde
tic

% Mapping to quantize colors
quantize = 2;
vecmap = 0:255;
vecmap = vecmap';
vecmap(:,2) = floor(vecmap(:,1)/quantize);

npoints = 6;
filtsigma = 3;
[histos, glotprobs, ~,~,~] = colorhist2(s(prevframe).cdata, shape, border, roimask, vecmap, npoints, filtsigma);
bpoints = cell2mat(histos(:,1));
toc
tic

% Closest base points for each ROI point
rpts = [rpts; [cg rg]];    % Ahora s� es la ROI entera, incluyendo glotis
idxs = dsearchn(bpoints, rpts);

% Calculate probability image
I = s(curframe).cdata;
pimage = zeros(size(shape));
%testpimage = zeros(size(shape));
testprobs = zeros(length(rpts),1);
for j = 1:length(rpts)
    color = double(reshape(I(rpts(j,2),rpts(j,1),:),1,3))/quantize;
    idx = idxs(j);

    histobg = cell2mat(histos(idx,2));
    histoglot = cell2mat(histos(idx,3));

    if quantize == 1
        color = color + 1;
        bglike = histobg(color(1), color(2), color(3));
        glotlike = histoglot(color(1), color(2), color(3));
    else
        bglike = trilinear_interp2(color, histobg, vecmap);
        glotlike = trilinear_interp2(color, histoglot, vecmap);
    end
    
    if bglike < 0
        bglike = 0;
    end

%     pglot = glotprobs(idx);
%     pbg = 1 - pglot;
    pglot = 0.5;
    pbg = 0.5;

    postprob = glotlike*pglot / (bglike*pbg + glotlike*pglot);
    if postprob < 0
        pimage(rpts(j,2), rpts(j,1)) = 0;
    else
        pimage(rpts(j,2), rpts(j,1)) = postprob * 255;
    end
    
    testprobs(j) = postprob;
end
toc

pimage = uint8(pimage);

figure(10)
subplot(1,3,1), image(pimage); title('Probability Image'); colormap(gray(255));
subplot(1,3,2), image(I)
subplot(1,3,3), hold off, image(s(prevframe).cdata), hold on, plot(bpoints(:,1), bpoints(:,2), 'y*', 'MarkerSize', 1)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% LEVEL-SET SEGMENTATION %%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

pbinimg = im2bw(pimage, 160.0/255);
se = strel('disk',1);
pbinimg = imopen(pbinimg,se);

% Level-set segmentation
pseg = test_fn_chenvese(pimage, pbinimg, 150, false, 1.2*255^2, 6);

% figure(5)
% subplot(2,2,1); image(I); title('Frame')
% subplot(2,2,2); image(pimage); title('Probability Image'); colormap(gray(255))
% subplot(2,2,3); imshow(pbinimg); title('Threshold')
% subplot(2,2,4); imshow(pseg); title('Level-set segmentation')

%% Plot filtered histogram level-set

% p = 3;
% histobg = cell2mat(histos(p,2));
% histoglot = cell2mat(histos(p,3));
% 
% 
% % Filtered histograms
% N = vecmap(end,2) + 1;
% L = round(100/quantize);
% [X,Y] = meshgrid(0:vecmap(end,2), 0:vecmap(end,2));
% bg_lset = reshape(histobg(:,L,:), N, N);
% glot_lset = reshape(histoglot(:,L,:), N, N);
% 
% figure(6)
% mesh(Y, X, bg_lset)
% xlabel('R')
% ylabel('B')
% 
% figure(9)
% mesh(Y, X, glot_lset)
% xlabel('R')
% ylabel('B')
% 
% pglot = 0.5;
% pbg = 0.5;
% figure(11)
% probs = glot_lset*pglot ./ (bg_lset*pbg + glot_lset*pglot);
% mesh(Y, X, probs)
% xlabel('R')
% ylabel('B')
% 
% 
% % Scatter plots
% bgdata = cell2mat(bgcell(p));
% glotdata = cell2mat(glotcell(p));
% 
% figure(7)
% scatter3(bgdata(:,1), bgdata(:,2), bgdata(:,3), 10, bgdata(:,4), 'filled')
% cb = colorbar;
% xlabel('R')
% ylabel('G')
% zlabel('B')
% colormap jet
% xlim([1 256])
% ylim([1 256])
% zlim([1 256])
% title('Background')
% 
% figure(8)
% scatter3(glotdata(:,1), glotdata(:,2), glotdata(:,3), 10, glotdata(:,4), 'filled')
% cb = colorbar;
% xlabel('R')
% ylabel('G')
% zlabel('B')
% colormap jet
% xlim([1 256])
% ylim([1 256])
% zlim([1 256])
% title('Glottis')






