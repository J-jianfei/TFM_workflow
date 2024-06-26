function imstack_new = translateImgStack(imstack,drift)

if size(imstack,3) ~= size(drift,1)
    error("Error in translateImgStack: imstack's number frames does not match the frames in drift table");
end

nframe = size(imstack,3);

for i = 1:nframe
    imstack_new(:,:,i) = imtranslate(imstack(:,:,i),drift(i,:),'cubic');
end


end