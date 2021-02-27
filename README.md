## Supermarket Sales on Shiny Dashboard

This project was done in to complete the Developing Data Products course by JHU via [coursera](https://www.coursera.org/specializations/jhu-data-science). The gif below provides a very brief tutorial of the dashboard, with its capability to utilize plotly for stacking and filter applications in many graphs, along with another tab continuously running a linear regression model to predict how much a customer will spend at their visit to the supermarket based on the many features the user can change.

![dashboard_gif](dashboard_example.gif)

A brief report on regression model selection is included here and can be seen [here](https://github.com/gdq12/Shiny_Dashboard/blob/master/model_eval.md).

The dashboard is up on the shiny server and can be visited [here](https://gdq12.shinyapps.io/shiny_dashboard/), although its advised **not to use chrome to visit the dashboard** since there are issues with java script in rendering plots and running the prediction. It has successfully functioned in safari server presently. A very brief project pitch prepared for the course was prepared using Rpres and uploaded to [Rbubs](https://rpubs.com/gdquiceno/657661).

### Update Feb 27, 2021 (setup app to EC2 AWS)

Can visit the dashboard hosted in the EC2 machine [here](http://3.122.192.213:3838/shinyapp/). Issue with rmarkdown rendering but graphs work much better.

**using Ubuntu Server 20.04 LTS (HVM) AMI with t2.Large**

Firewall for shiny server:
inbound rules -> add rule:
* type: Custom TCP
* Port range: 3838
* source: 0.0.0.0/0

1. accessing EC2 machine via terminal

```
cd /path2directory/Shiny_Dashboard

# change rights to *.pem file
chmod 400 feb_2021.pem

# enter EC2 machine via terminal
ssh -i "feb_2021.pem" Public IPv4 DNS
```

2. Install packages

* R installation based on suggestions from [R website](https://rstudio.com/products/shiny/download-server/ubuntu/)
* can also use a Rstudio premade AMI from [here](https://www.louisaslett.com/RStudio_AMI/)
* another good guide [here](https://www.charlesbordet.com/en/guide-shiny-aws/#1-how-to-access-the-default-shiny-app)

```
# add cran repo
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9

sudo add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/'

# update machine
sudo apt-get update

# install R
sudo apt install r-base r-base-dev

# install shiny (takes a while)
sudo R
install.packages("shiny")
# OR
sudo su - \
-c "R -e \"install.packages('shiny', repos='https://cran.rstudio.com/')\""

# install shiny server (with dependencies)
sudo apt-get install gdebi-core

wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-1.5.16.958-amd64.deb

sudo gdebi shiny-server-1.5.16.958-amd64.deb
```


3. Move files into instance

```
# compress files (in local machine)
tar -czvf 2AWS.tar.gz shinyapp

# push to machine
scp -i feb_2021.pem 2AWS.tar.gz ubuntu@PublicIPv4DNS:~/.

# unzip in machine and move into another folder
tar -xzvf 2AWS.tar.gz

rm 2AWS.tar.gz
```

4. Implement imported files in shiny server app

```
# create shortcut from shiny server to home directory
cd /srv/shiny-server/

sudo ln -s ~/shinyapp

# remove default files
sudo rm index.html

sudo rm -R sample-apps
```


5. change config file to customize landing page

```
# edit config file
sudo nano /etc/shiny-server/shiny-server.conf

# what the file should look like:

# Instruct Shiny Server to run applications as the user "shiny"
run_as shiny;

preserve_logs true;

# Define a server that listens on port 3838
server {
  listen 3838;

  # Define a location at the base URL
  location / {

    # Host the directory of Shiny Apps stored in this directory
    site_dir /srv/shiny-server;

    # Log all Shiny output to files in this directory
    log_dir /var/log/shiny-server;

    # When a user visits the base URL rather than a particular application,
    # an index of the applications available in this directory will be shown.
    directory_index off;
    app_init_timeout 250;
  }
}

# possible addition to configuration file?
app_init_timeout 250;
```

6. Check logs for bugs and launch of dashboard

```
# go to log directory
cd /var/log/shiny-server

# check logs
sudo tail shiny.....log
```

7. Install needed libraries
**if install packages within R install.packages(), then must be in shiny user mode!**

```
# change to shiny user
sudo su - shiny

# go into R and install packages
R

install.packages(c("dplyr", "knitr"))

install.packages("leaflet")

sudo su - -c "R -e \"install.packages('rmarkdown', repos='https://cran.rstudio.com/')\""

install.packages('forecast', dependencies = TRUE)

sudo apt-get install -y r-cran-shinydashboard

sudo apt-get install -y r-cran-car

# then check logs again to make sure there are no other rendering issues (go back to ubuntu user w/exit)
```
