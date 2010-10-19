[Poodle](../index.html) Customise [Solr](http://lucene.apache.org/solr/)
======================================

I'm assuming you have followed all the recommended [installation](../file.INSTALLATION.html) instructions and are now in the final phase of configuring Solr.
    
Currently Poodle uses a re-configured "version" of the Solr example project. To configure Solr for Poodle, copy the following files from `./Poodle/solr/1.4.1/conf/` into the Solr example project:
    
- `schema.xml`
- `solrconfig.xml`

These need to be copied to: `/apache-solr-1.4.1/example/solr/conf`, *replacing* the existing files **back them up first if paranoid!**

Note: You may also need to adjust the multipartUploadLimitInKB attribute if you are submitting very large documents. See the Solr documentation related to Solr Cell. In general I recommend you read up on Solr because it's at the heart of Poodle and if you want to tweak this tool further you will need more knowledge on this subject.

Once Solr is configured you need to move on to [indexing](../scripts/index.html) or if you like return to [Common/Remaining Set-up](../file.INSTALLATION.html#Set-up_Environment)
