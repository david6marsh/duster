
<!-- README.md is generated from README.Rmd. Please edit that file -->

# duster

‘duster’ is a `shiny` webapp focused on removing large scale dust from
old photographs. If you can’t face clicking on each of scores of dust
spots in each of many images with some ‘heal’ tool, or your favourite
photo tool leaves ‘dusted’ images looking widely blurred, then ‘duster’
might help.

Duster shows you exactly where it has detected dust. It only changes the
pixels there.

## Quick ‘how-to’

The quick steps are as follows. There is more explanation of each step
in the following section.

1.  Upload a jpeg. It will be shown, together with the dust detected
    using the default settings.
2.  If there is a ‘black’ border, it will be mostly removed. If too much
    is being removed, reduce the edge crop strength.
3.  Check the dust. If not enough is being found, increase the detection
    radius or reduce the detection threshold. It’s likely that some
    larger pieces will escape.
4.  Check the dust again. If it is showing real structure from the image
    (eg mouth, fabric texture), increase the detection threshold.
5.  If dust is found, but the result still looks dark or grey where the
    dust spot is, try increasing the replacement radius.
6.  If you’re finding fine ‘rings’ like water droplet stains around
    dust, try fattening the dust.
7.  When you’re happy, download the image to your browser’s default
    download folder.

Reset: returns to default values.

## More details

The final image is shown on the left, the dust is shown on the right. If
you choose that option, the original is shown below.

### Border removal

This step removes any ‘plain’ border from the image, such as a black
border from a scanned slide. A setting of 0 means that any edge row or
column of pixels that are identical in intensity will be removed. (These
could be all identical grey, or all black, say.)

In practice, particularly if the image is jpeg, even if it looks like
the border is just black, it won’t be: there will be pixels very near
black, but not black. Increasing the tolerance will allow for that
‘insignificant’ variation. What’s insignificant will vary between
photos.

### Dust in the final image

The dust that has been found is shown as bright dots on a black
background. They will be white for black and white images, or colour for
colour images. **duster only changes the image for those bright
pixels**, the black areas will be unchanged.

If there is ‘obvious’ dust in the final, for example in patches of sky
or skin, check the dust pattern. If there is no bright spot in the
corresponding place, increase the detection radius or reduce the
detection threshold.

### Non-dust in the dust image

Increasing the detection radius is likely to bring *real* image
structure into the dust image. Real, fine structure like fabric
patterns, lines that are small gaps (between fingers, between lips),
telegraph poles will appear in the dust image. If this non-dust is not
very bright in the dust image, then increasing the threshold will remove
it. Otherwise you need to find a detection radius that is a balance
between finding dust and not finding real image features.

### Dust remains grey

The pixels of ‘dust’ are replaced by the median pixel nearby. Normally,
this will give a reasonable, non-dust value. Occasionally you might need
to increase the radius for this median averaging to get a better result.
(This is the slowest step of the process.)

### ‘Water stains’ around dust

Particularly if the source is a jpeg, the dust will have been smudged,
and this can also produce a slightly-brighter ‘ring’ around each piece
of dust. A clunky solution is to ‘fatten’ the dust: add extra pixels
around each dust spot for replacement.

## License & Acknowledgements

‘duster’ is subject to the [license](LICENSE.md). The code is [available
on github](https://github.com/david6marsh/duster).

It makes heavy use of the
[`shiny`](https://cran.r-project.org/package=shiny) and
[`magick`](https://cran.r-project.org/package=magick) packages. Consult
their documentation for the licenses which apply.
