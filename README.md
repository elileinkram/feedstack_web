# About

[Feedstack](https://feedstack.dev) is a progammable social network.

We give developers the tools to make and share their own feeds.

That means you can decide what posts enter the feed. And the order in which they appear. 

You can install [Feedstack](https://feedstack.dev) on [IOS](https://apps.apple.com/us/app/feedstack-find-your-feed/id1534175629?app=itunes&ign-mpt=uo%3D4) and on [Android](https://play.google.com/store/apps/details?id=com.jasper.jasper).

# How it works

Each post has a ranking number.

A post with a higher ranking will show up in the feed before a post with a lower ranking.

The ranking is calculated by [computeRanking](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/ranking/compute_ranking.js).

The [computeRanking](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/ranking/compute_ranking.js) function takes in 3 classes as input.

[Author](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/classes/author.js), [Post](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/classes/post.js) and [Reader](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/classes/reader.js).

And then spits back a number as output, which becomes the new ranking.

Upload your implementation of [computeRanking](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/ranking/compute_ranking.js) to [Feedstack](https://feedstack.dev).

[Feedstack](https://feedstack.dev) will then generate a new feed based on the new implementation. 

# Rules

If [computeRanking](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/ranking/compute_ranking.js) returns a number that is less than or equal to zero, then the post will not enter the feed.

If your implementation of [computeRanking](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/ranking/compute_ranking.js) does not follow the same structure as the one shown [here](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/ranking/compute_ranking.js) then it will not work. 

# Examples

[In Dogs We Trust](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/functions/in_dogs_we_trust.js)

[The Road Not Taken](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/functions/the_road_not_taken.js)

[FOMO](https://github.com/elijahleinkram/feedstack/blob/master/feedstack_website/functions/fomo.js)












