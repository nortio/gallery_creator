# gallery_creator
Generate a simple image gallery from a folder with photos.

## Usage

**!!! ImageMagick is required !!!**
Generate an image gallery named "My Gallery" in folder `output` by using photos located in the `input` folder:

```
gallery_creator -output=output/ -title="My gallery" input/
```
The program autmatically optimizes images and converts them to **webp**. You can also add comments to each image by modifying the `list.json` file in the output folder. Once done, re-run the same command.
Default allowed extensions: `"jpg", "jpeg", "png", "webp"`

```
gallery_creator [options] [input...]
  Input can be a folder or multiple files

Options:
  -h, --help                              Display this message
  -e=[ext,...], --extensions=[ext,...]    Allowed extensions
  -o, --output                            Output directory
  -p, --page-only                         Skip image optimization and output only html page
  -t, --title                             Gallery title
```
