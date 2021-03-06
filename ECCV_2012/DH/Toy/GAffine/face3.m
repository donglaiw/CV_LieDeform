dset.ns = 16;
dset.siz = [100 100];
%dset.siz = [32,32];
numpix = prod(dset.siz);
dset.data = struct([]);

for j = 1 : 16
    if j<10
        nn=['00' num2str(j)];
    else
        nn=['0' num2str(j)];
    end
    a = dir(['FaceH/' nn '*.jpg']);
    
    dset.data(j).n = length(a)-1;
    dset.data(j).nbs = zeros(numpix,length(a));
    for k = 1 : length(a)
        bb = double(rgb2gray(imread(['FaceH/' a(k).name])));
        cc = imresize(imfilter(bb,fspecial('gaussian',7,1.),'same','replicate'),dset.siz,'bicubic');
        dset.data(j).nbs(:,k) = cc(:);
        dset.data(j).nbs(:,k) = 0.5+0.1*(dset.data(j).nbs(:,k)-mean(dset.data(j).nbs(:,k)))/std(dset.data(j).nbs(:,k),1);       
    end
end


ind = cellfun(@isempty,{dset.data.nbs});
dset.ns = 16 - sum(ind);
dset.data(ind==1)=[];

dismat=zeros(dset.ns);
labelmat=zeros(dset.ns,dset.ns,2);
for j = 1 : dset.ns
    for k = j+1 : dset.ns
        tmp = pdist2(dset.data(j).nbs',dset.data(k).nbs');
        [aa,bb] = min(tmp);
        [cc,dd] = min(aa);
        dismat(j,k)=cc;
        labelmat(j,k,1) = dd;%col
        labelmat(j,k,2) = bb(dd);%row
        labelmat(k,j,1) = bb(dd);%col
        labelmat(k,j,2) = dd;%row
    end
end


%minimax
src = 4;
tar = 2;
sp = 62;
[~, tp] = min( sum(bsxfun(@minus,dset.data(tar).nbs,dset.data(src).nbs(:,sp)).^2));
testimg = dset.data(tar).nbs(:,tp);
figure;subplot(1,2,1);imagesc(reshape(testimg,dset.siz));subplot(1,2,2);imagesc(reshape(dset.data(src).nbs(:,sp),dset.siz));colormap gray;

%10 medoid
D = pdist2(dset.data(src).nbs',dset.data(src).nbs');
center=[sp,4,8,13,16,19,25,29,58];
[~, label] = min(D(center,:));
K = length(center);
center(1)=sp;
see2(center,dset.data(src).nbs')

cellsize=3;
gridspacing=1;

%{
SIFTflowpara.alpha=2*255;
SIFTflowpara.d=40*255;
SIFTflowpara.gamma=0.00001*255;
SIFTflowpara.nlevels=4;
SIFTflowpara.wsize=2;
SIFTflowpara.topwsize=10;
SIFTflowpara.nTopIterations = 60;
SIFTflowpara.nIterations= 30;
%}
SIFTflowpara.alpha=0.2*255;
SIFTflowpara.d=0.4*255;
SIFTflowpara.gamma=0.01*255;
SIFTflowpara.nlevels=4;
SIFTflowpara.wsize=2;
SIFTflowpara.topwsize=4;
SIFTflowpara.nTopIterations = 60;
SIFTflowpara.nIterations= 30;


tmps=zeros([dset.siz,K]);
 tmps(:,:,1) = reshape(testimg,dset.siz);
for i = 1 : K
	sift1 = mexDenseSIFT(255*reshape(dset.data(src).nbs(:,center(i)),dset.siz),cellsize,gridspacing);
	sift2 = mexDenseSIFT(255*reshape(testimg,dset.siz),cellsize,gridspacing);
[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);

tmps(:,:,i)=warpImage(reshape(testimg,dset.siz),vx,vy);
 tmp = tmps(:,:,i);
 [i, max(abs(vx(:))),sum((tmp(:)-dset.data(src).nbs(:,center(i))).^2),sum((tmp(:)-testimg).^2)]
end
for i = 1 : K
subplot(2,10,i)
imagesc(reshape(dset.data(src).nbs(:,center(i)),dset.siz))
subplot(2,10,10+i)
imagesc(tmps(:,:,i))
end
colormap gray




%{
sift1 = mexDenseSIFT(255*reshape(dset.data(src).nbs(:,center(1)),dset.siz),cellsize,gridspacing);
sift2 = mexDenseSIFT(255*reshape(dset.data(src).nbs(:,center(5)),dset.siz),cellsize,gridspacing);
[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);
warpI2=warpImage(reshape(dset.data(src).nbs(:,center(5)),dset.siz),vx,vy);
%figure;
subplot(1,3,1);
imagesc(reshape(dset.data(src).nbs(:,center(1)),dset.siz));
subplot(1,3,2);
imagesc(warpI2);
subplot(1,3,3);
imagesc(reshape(dset.data(src).nbs(:,center(5)),dset.siz));
colormap gray;
%}


%%%%%%%% 1 manifold
for j= 1:dset.ns
    [~, pos] = min( sum(bsxfun(@minus,dset.data(j).nbs,testimg).^2));
    dset.data(j).seed = dset.data(j).nbs(:,pos);
    dset.data(j).nbs(:,pos) = [];
    dset.data(j).n=size(dset.data(j).nbs,2);
    dset.data(j).w = ones(1,dset.data(j).n);
    dset.data(j).Vx = zeros(numpix,dset.data(j).n);
    dset.data(j).Vy = zeros(numpix,dset.data(j).n);
    for k = 1 : dset.data(j).n
	sift1 = mexDenseSIFT(255*reshape(dset.data(j).nbs(:,k),dset.siz),cellsize,gridspacing);
	sift2 = mexDenseSIFT(255*reshape(dset.data(j).seed,dset.siz),cellsize,gridspacing);
[vx,vy,energylist]=SIFTflowc2f(sift1,sift2,SIFTflowpara);
        dset.data(j).Vx(:,k) = vx(:);
        dset.data(j).Vy(:,k) = vy(:);
end
end
addpath('/home/donglai/Desktop/ECCV/eccv12_codes')
p=0.9;tol=1e-3;maxiter=100;
[B0, evs] = dm_init_basis(dset, p);
[B2, A2] = dm_train(dset, B0, maxiter, tol);

tmps2=zeros([dset.siz,K]);
 tmps2(:,:,1) = reshape(testimg,dset.siz);
tmps3=zeros([dset.siz,K]);
 tmps3(:,:,1) = reshape(dset.data(src).nbs(:,center(i)),dset.siz);
for i = 2 : K
 [tmps3(:,:,i),tmps2(:,:,i)] = dm_solve(B2,reshape(dset.data(src).seed,dset.siz),reshape(dset.data(src).nbs(:,center(i)),dset.siz),1.3e-4,reshape(testimg,dset.siz));
 tmp = tmps2(:,:,i);
 [i, max(abs(vx(:))),sum((tmp(:)-dset.data(src).nbs(:,center(i))).^2),sum((tmp(:)-testimg).^2)]
end


for i = 1 : K
subplot(4,10,i)
imagesc(reshape(dset.data(src).nbs(:,center(i)),dset.siz))
subplot(4,10,10+i)
imagesc(tmps(:,:,i))
subplot(4,10,20+i)
%imagesc(tmps2(:,:,i))
subplot(4,10,30+i)
%imagesc(reshape(testimg,dset.siz))
end
colormap gray







alpha = 0.035;
ratio = 0.5;
minWidth = 8;
nOuterFPIterations = 20;
nInnerFPIterations = 5;
nSORIterations = 30;
para = [alpha,ratio,minWidth,nOuterFPIterations,nInnerFPIterations,nSORIterations];

tmps0=zeros([dset.siz,tp]);
for i = 2 : K
 [vx ,vy] = Coarse2FineTwoFrames( reshape(dset.data(src).nbs(:,center(i)),dset.siz), reshape(dset.data(src).nbs(:,sp),dset.siz),para);
 tmps0(:,:,i) = Coarse2FineTwoFrames( reshape(dset.data(src).nbs(:,center(i)),dset.siz), reshape(dset.data(src).nbs(:,sp),dset.siz),para);
 tmp = tmps0(:,:,i);
 [i, max(abs(vx(:))),sum((tmp(:)-dset.data(src).nbs(:,center(i))).^2),sum((tmp(:)-dset.data(src).nbs(:,sp)).^2)]
end
for i = 1 : K
subplot(10,3,3*i-2)
imagesc(reshape(dset.data(src).nbs(:,center(i)),dset.siz))
subplot(10,3,3*i-1)
imagesc(tmps0(:,:,i))
subplot(10,3,3*i)
imagesc(reshape(dset.data(src).nbs(:,sp),dset.siz))
end


%{

% 1) direct matching
tmps=zeros([dset.siz,tp]);
for i = 2 : K
 [vx ,vy] = Coarse2FineTwoFrames( reshape(dset.data(src).nbs(:,center(i)),dset.siz), reshape(testimg,dset.siz),para);
 tmps(:,:,i) = Coarse2FineTwoFrames( reshape(dset.data(src).nbs(:,center(i)),dset.siz), reshape(testimg,dset.siz),para);
 tmp = tmps(:,:,i);
 [i, max(abs(vx(:))),sum((tmp(:)-dset.data(src).nbs(:,center(i))).^2),sum((tmp(:)-testimg).^2)]
end

for i = 1 : K
subplot(10,3,3*i-2)
imagesc(reshape(dset.data(src).nbs(:,center(i)),dset.siz))
subplot(10,3,3*i-1)
imagesc(tmps(:,:,i))
subplot(10,3,3*i)
imagesc(reshape(testimg,dset.siz))
end


addpath('/home/donglai/Desktop/ECCV/eccv12_codes')
%2) tangent space alone
p = 0.95;
maxiter = 100;
tol = 1e-3;
dset2 = dset;
dset2.ns = 1;
dset2.data([1:src-1,src+1:end])=[];
dset2.data(1).seed = dset2.data(1).nbs(:,sp);
dset2.data(1).nbs(:,sp) = [];
dset2.data(1).n=size(dset2.data(1).nbs,2);
dset2.data(1).w=ones(1,dset2.data(1).n);
for k = 1 : dset2.data.n
    [vx ,vy] = Coarse2FineTwoFrames( reshape(dset2.data(1).nbs(:,k),dset2.siz), reshape(dset2.data(1).seed,dset2.siz),para);
    dset2.data(1).Vx(:,k) = vx(:);
    dset2.data(1).Vy(:,k) = vy(:);
end
[B0, evs] = dm_init_basis(dset2, p);
[B2, A2] = dm_train(dset2, B0, maxiter, tol);


tmps2=zeros([dset.siz,K]);
for i = 2 : K
 %tmps2(:,:,i) = deform_img(reshape(testimg,dset.siz), B2,A2{1}(:,center(i)))';
 % coordinate 1st order linear combine

 tmps2(:,:,i) = dm_solve(B2, reshape(testimg,dset.siz),  reshape(dset.data(src).nbs(:,center(i)),dset.siz),1e-4);
 tmp = tmps2(:,:,i);
 [i, max(abs(vx(:))),sum((tmp(:)-dset.data(src).nbs(:,center(i))).^2),sum((tmp(:)-testimg).^2)]
end
figure
for i = 1 : K
subplot(10,4,4*i-3)
imagesc(reshape(dset.data(src).nbs(:,center(i)),dset.siz))
subplot(10,4,4*i-2)
imagesc(tmps(:,:,i))
subplot(10,4,4*i-1)
imagesc(tmps2(:,:,i))
subplot(10,4,4*i)
imagesc(reshape(testimg,dset.siz))
end


%3) shared tangent spaces

