#include <stdint.h>
#include <dirent.h>

#define STB_IMAGE_IMPLEMENTATION
#include "stb/stb_image.h"

#define SIZE UINT_MAX

const char *byte_to_binary(uint8_t x)
{
    static char b[33];
    b[0] = '\0';

    unsigned long int z;
    for (z = 255; z > 0; z >>= 1)
    {
        strcat(b, ((x & z) == z) ? "1" : "0");
    }

    return b;
}

void processImage(char file[]) {

    int width, height, bpp;
    
    char png_dir[512] = "";
    strcat(png_dir, "./mnist_png/training/0/");
    strcat(png_dir, file);


    
    uint8_t *rgb_image = stbi_load(png_dir, &width, &height, &bpp, 0);
    FILE *fptr;

    char bin_dir[512] = "";
    strcat(bin_dir, "./mnist_bin/training/0/");
    char *dot = strrchr(file, '.');
    *dot = '\0';
    strcat(bin_dir, file);

    printf("old dir: %s\n", png_dir);
    printf("new dir: %s\n", bin_dir);

    fptr = fopen(bin_dir, "wb");

    printf("h = %d\nw = %d\nn = %d\n", height, width, bpp);

    for (int i = 0; i < height; ++i)
    {
        for (int j = 0; j < width; ++j)
        {
            uint8_t im = (float)rgb_image[i * width + j];
            fprintf(fptr, "%s\n", byte_to_binary(im));
            //printf(" %3.1f ", (float)rgb_image[i * width + j] / 255);
        }
        printf("\n");
    }

    stbi_image_free(rgb_image);
}

int main(int argc, char* argv[])
{
    DIR *dir;
    struct dirent *entry;

    // Open the current directory
    
    dir = opendir("./mnist_png/training/0");
    
    if (dir == NULL) {
        perror("Error opening directory");
        return 1;
    }

    int n = 20;

    while (n != 0) { // condition: (entry = readdir(dir)) != NULL
        entry = readdir(dir);
        
    
        if (entry->d_type == DT_REG) {
            printf("---------->%s\n", entry->d_name);
            // Check if the file has a supported image extension
            
            const char *ext = strrchr(entry->d_name, '.');
            printf("---------->%s\n", ext);
            if (ext != NULL && (strcmp(ext, ".png") == 0)) {
                // Full path to the image file
                char filepath[1024];
                snprintf(filepath, sizeof(filepath), "%s", entry->d_name);
                printf("file: %s\n", filepath);

                // Process the image
                processImage(filepath);
                printf("after");
            }
        }
        n--;
    }

    // Close the directory
    closedir(dir);

    return 0;
}