function  final_image = ms()
	%Parameter and variable declaration
    image_path = 'Segmentation_Data/BaboonRGB.bmp';
    scale_image = 0.25;
    number_of_iteration_mean_shift = 10;
    bandwidth_mean_shift = 20;
    difference_threshold_clustering = 10;

    %Start of the implementation
    img = imread( image_path );
    dimen = size(img, 3);

    if dimen == 1
        colormap('gray')
    end

    %Scale image
    image_scaled = resize_image( img, scale_image);

    %Display original scaled image
    subplot(2,3,1);
    imagesc(image_scaled);
    title('Original Scaled image');

    disp("Original size of image: ");
    disp(size(img));

    disp("Scaled size of image: ");
    disp(size(image_scaled));

    %Perform Mean Shift with k iteration and h as window width
    if dimen == 1    
        k=number_of_iteration_mean_shift;
        h=bandwidth_mean_shift;
        image_scaled_vector = image_scaled(:);
        ms_vector = mean_shift( double(image_scaled_vector), h, k);
        ms_image  = reshape(ms_vector,size(image_scaled,1),size(image_scaled,1));
    else
       ms_image = do_mean_shift_color_image( image_scaled, bandwidth_mean_shift, number_of_iteration_mean_shift, scale_image ); 
    end

    %Display image after mean shift
    subplot(2,3,2);
    imagesc( ms_image );
    title('After Mean Shift' );

    if dimen == 1
        subplot(2,3,5);
        plot(ms_vector);
        title('After Mean Shift');  
    end

    disp("Size of mean shifted image: ");
    disp(size(ms_image));  

    %Perform clustering only for Gray Scale images
    if dimen == 1
        ms_cluster_vector = clustering( ms_vector, difference_threshold_clustering);
        ms_cluster_image = reshape(ms_cluster_vector,size(image_scaled,1),size(image_scaled,1));

        disp("Size of clustered image: ");
        disp(size(ms_cluster_vector));

        %Display image after clustering
        subplot(2,3,3);
        imagesc( ms_cluster_image );
        title('After Clustering');

        subplot(2,3,6);
        plot(ms_cluster_vector);
        title('After Clustering');

    end

    %Returning the final value
    if dimen == 1
        final_image = ms_cluster_image;
    else
        final_image = ms_image;
    end

end


%Function to resize the image
function scaled_image = resize_image( img, scale)
    dimen = size( img, 3);
    if dimen == 1
        scaled_image = imresize(img, scale);
    else
        imageR = img(:,:,1);
        imageG = img(:,:,2);
        imageB = img(:,:,3);

        imageR = imresize(imageR, scale);
        imageG = imresize(imageG, scale);
        imageB = imresize(imageB, scale);

        scaled_image(:,:,1) = imageR;
        scaled_image(:,:,2) = imageG;
        scaled_image(:,:,3) = imageB;
    end
end

%Function to perform convergence in Mean Shift for black and white image
function pixel_value = converge(k, image_vector, pixel_index, h) 
   while(k > 0) 
        numerator = 0;
        denominator = 0;    
        for index = 1 : size(image_vector,1)
            kernel_value = exp(-1 * ((image_vector(pixel_index) - image_vector(index)).^2)./h.^2);
            numerator = numerator + kernel_value.*image_vector(index);
            denominator = denominator + kernel_value;
        end
        image_vector(pixel_index) = numerator./denominator;
        k = k-1;
   end 

   pixel_value = image_vector(pixel_index);
end

%Function to perform Mean Shift for black and white image
function ms_vector = mean_shift(ms_image_vector, bandwidth_mean_shift, number_of_iteration_mean_shift)
    for index = 1:size(ms_image_vector,1)
       ms_vector( index ) = converge(number_of_iteration_mean_shift, double(ms_image_vector), index, bandwidth_mean_shift);
    end
end


%Function to get cluster helper which will be used for clustering
function cluster_helper = get_cluster_helper(sorted_vector, threshold_difference)
    k = 1;
    items = 1;
    mean = sorted_vector(1);

    for index = 2 : size(sorted_vector,2)
        difference = abs( sorted_vector(index) - mean );
        if difference > threshold_difference
            cluster_helper(k,:) = [ index-1 , mean ];
            k = k + 1;
            items = 1;
            mean = sorted_vector(index);
        else
            mean = (mean * items + sorted_vector(index)) / (items + 1);
            items = items + 1;
        end
    end

    cluster_helper(k,:) = [size(sorted_vector,2) , mean];
end


%Function to create clusters
function clustered_image = clustering( ms_vector, threshold_difference )
    [sorted_vector , indexes] = sort(ms_vector);
    cluster_helper = get_cluster_helper(sorted_vector, threshold_difference);

    %Assign clustered values to the mean shifted image
    start = 1;
    for index_cluster_helper  = 1:size(cluster_helper,1)
        cluster_details = cluster_helper(index_cluster_helper,:);
        cluster_index = cluster_details(1);
        cluster_value = cluster_details(2);
        for index_ms_vector = start:cluster_index
            clustered_image(indexes(index_ms_vector)) = cluster_value;
        end
        start = cluster_index + 1;
    end
end


%Function to perform convergence in Mean Shift for RGB image
function [pixel_valueR, pixel_valueG, pixel_valueB] = converge_color(k, image_vectorR, image_vectorG, image_vectorB, pixel_index, h) 
   while(k > 0) 
        numeratorR = 0;
        denominatorR = 0;    

        numeratorG = 0;
        denominatorG = 0;    

        numeratorB = 0;
        denominatorB = 0;    

        for index = 1 : size(image_vectorR,1)
            kernel_valueR = exp(-1 * ((image_vectorR(pixel_index) - image_vectorR(index)).^2)./h.^2);
            numeratorR = numeratorR + kernel_valueR.*image_vectorR(index);
            denominatorR = denominatorR + kernel_valueR;

            kernel_valueG = exp(-1 * ((image_vectorG(pixel_index) - image_vectorG(index)).^2)./h.^2);
            numeratorG = numeratorG + kernel_valueG.*image_vectorG(index);
            denominatorG = denominatorG + kernel_valueG;

            kernel_valueB = exp(-1 * ((image_vectorB(pixel_index) - image_vectorB(index)).^2)./h.^2);
            numeratorB = numeratorB + kernel_valueB.*image_vectorB(index);
            denominatorB = denominatorB + kernel_valueB;
        end

        image_vectorR(pixel_index) = numeratorR./denominatorR;
        image_vectorG(pixel_index) = numeratorG./denominatorG;
        image_vectorB(pixel_index) = numeratorB./denominatorB;

        k = k-1;
   end 

   pixel_valueR = image_vectorR(pixel_index);
   pixel_valueG = image_vectorG(pixel_index);
   pixel_valueB = image_vectorB(pixel_index);
end


%Functions for Colored Image Mean Shift

%Function to perform Mean Shift for color image
function [ms_vectorR, ms_vectorG, ms_vectorB] = mean_shift_color(image_vectorR, image_vectorG, image_vectorB, bandwidth_mean_shift, number_of_iteration_mean_shift)
    for index = 1:size(image_vectorR,1)
        [pixel_valueR, pixel_valueG, pixel_valueB] = converge_color(number_of_iteration_mean_shift, image_vectorR, image_vectorG, image_vectorB, index, bandwidth_mean_shift); 

        ms_vectorR( index ) = pixel_valueR;
        ms_vectorG( index ) = pixel_valueG;
        ms_vectorB( index ) = pixel_valueB;
    end
end


%Helper function to perform Mean Shift on Color Image
function ms_image = do_mean_shift_color_image(img, bandwidth_mean_shift, number_of_iteration_mean_shift, scale_image)
    imageR = img(:,:,1);
    imageG = img(:,:,2);
    imageB = img(:,:,3);

    [ms_vectorR, ms_vectorG, ms_vectorB] = mean_shift_color(double(imageR(:)), double(imageG(:)), double(imageB(:)), bandwidth_mean_shift, number_of_iteration_mean_shift);

    ms_imageR = reshape(ms_vectorR, size(imageR,1), size(imageR,1));
    ms_imageG = reshape(ms_vectorG, size(imageG,1), size(imageG,1));
    ms_imageB = reshape(ms_vectorB, size(imageB,1), size(imageB,1));

    ms_image(:,:,1) = uint8(ms_imageR);
    ms_image(:,:,2) = uint8(ms_imageG);
    ms_image(:,:,3) = uint8(ms_imageB);
end

