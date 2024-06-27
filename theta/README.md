SmartSim + SmartRedis
=======================

> **See [old README](old-README.md) for more information, this just contains changes required for ARCHER2.** 

1. Automates deployment of HPC worloads (Redis).
2. Makes ML frameworks callable from Fortran/C HPC simulations.

SmartSim = Infrastructure library\
SmartRedis = Client library 

Example - [Online Training:](https://www.craylabs.org/docs/tutorials/ml_training/surrogate/train_surrogate.html)
* A NN is trained to act like a surrogate model to solve a physical problem. 
* The training dataset is constructed by running simulations while the model is being trained. 
* For each simulation, the initial conditions and the steady state soliution are put on the database. 
* The data will be used to train a NN
* SmartSim is used to launch the database, the simularion and the NN training locally but in separate processes. 
* Running an ensemble of simulations. 

[Documentation here.](https://www.craylabs.org/docs/overview.html)

</br>
</br>
</br>

Building for ARCHER2: 
----------------------

```bash
export PREFIX=/path/to/install/location
module load cmake
module swap PrgEnv-cray PrgEnv-gnu
module load cray-fftw

cd $PREFIX
```

Create a new environment: 
```bash 
wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash ./Miniconda3-latest-Linux-x86_64.sh
#When installing make sure you install miniconda in the correct PREFIX 
#Make sure that miniconda is install in /work not /home

eval "$($PREFIX/miniconda3/bin/conda shell.bash hook)" 
conda create -n a2-smartsim python=3.10
conda activate a2-smartsim
#Check set-up is NOT pointing to a centralised location: 
which python
```

<!-- Installing git-lfs from source if needed: 

```bash 
# Install go 
wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz
tar -xvf go1.22.3.linux-amd64.tar.gz 
export PATH=$PATH:/work/z19/z19/eleanorb/wind-rl/smartsim/go/bin/

wget https://github.com/git-lfs/git-lfs/releases/download/v3.5.1/git-lfs-linux-amd64-v3.5.1.tar.gz
tar -xvf git-lfs-linux-amd64-v3.5.1.tar.gz
cd git-lfs-3.5.1/
# Update install path to /work/z19/z19/eleanorb/wind-rl/smartsim/git-lfs 
mkdir /work/z19/z19/eleanorb/wind-rl/smartsim/git-lfs
./install.sh 

# Git LFS initialized.

export PATH=$PATH:/work/z19/z19/eleanorb/wind-rl/smartsim/git-lfs/bin/
git lfs version
git-lfs/3.5.1 (GitHub; linux amd64; go 1.21.7; git e237bb3a)

``` -->

Build SmartSim and SmartRedis: 
```bash 
export CRAYPE_LINK_TYPE=dynamic
git clone https://github.com/CrayLabs/SmartSim.git
cd SmartSim
pip install -e .[dev]
cd .. 
git clone https://github.com/CrayLabs/SmartRedis.git
cd SmartRedis
make lib-with-fortran
pip install .
cd ../SmartSim 
conda install git-lfs -y 
git lfs version
# git-lfs/3.5.1 (GitHub; linux amd64; go 1.21.7; git e237bb3a)
smart build --device cpu
```

Example output: 
```bash 
[SmartSim] INFO Running SmartSim build process...
[SmartSim] INFO Checking requested versions...
[SmartSim] INFO Redis build complete!

ML Backends Requested
╒════════════╤════════╤═══════╕
│ PyTorch    │ 2.0.1  │ True  │
│ TensorFlow │ 2.13.1 │ True  │
│ ONNX       │ 1.14.1 │ False │
╘════════════╧════════╧═══════╛

Building for GPU support: False

[SmartSim] INFO Building RedisAI version 1.2.7 from https://github.com/RedisAI/RedisAI.git/
[SmartSim] INFO ML Backends and RedisAI build complete!
[SmartSim] INFO Torch, Tensorflow backend(s) built
[SmartSim] INFO Torch version not found in python environment. Attempting to install via `pip`
[SmartSim] WARNING Python Env Status Warning!
Requested Packages are Missing or Conflicting:

Missing:
	tensorflow==2.13.1

Consider installing packages at the requested versions via `pip` or uninstalling them, installing SmartSim with optional ML dependencies (`pip install smartsim[ml]`), and running `smart clean && smart build ...`
[SmartSim] INFO SmartSim build complete!
```


</br>
</br>
</br>


Running Examples: SmartSim-Zoo Theta 
======================================

Set-up: 
--------
```bash 
cd $PREFIX
git clone https://github.com/eleanor-broadway/SmartSim-Zoo.git
cd SmartSim-Zoo/theta 
```

I have set-up submission scripts for each, but you can run an interactive job like this:  
```bash 
salloc --nodes=3 --ntasks-per-node=128 --cpus-per-task=1 --time=00:20:00 --partition=standard --qos=short --account=z19

eval "$($PREFIX/miniconda3/bin/conda shell.bash hook)" 
conda activate a2-smartsim 
```

</br>

launch_distributed_model.py 
----------------------------

* Simple model which runs a hello world on each processor. Using 3 nodes and 20 processes per node (60 total). 
* Setting up an "experiment". 
* Sets number of tasks per node and total number of tasks. 

```bash 
cc hello.c -o hello
sbatch launch_distributed_model.sh 
```

* In submission script: specify 3 nodes, 128 tasks-per-node. Launching with "python" NOT srun. 
* In code: specifying 20 tasks-per-node, 60 total. 
* Output: correctly see hello from 20 cores on 3 nodes. (If we were just launching "srun hello" then we would see all 128 cores say hello). 
* successfully picks up srun, slurm and jobid from env. 
* Using logging, we can see that it launches a hello_world job with jobid.0. If launching interactively and launching multiple times in the same allocation, each new hello_world will have the id: jobid.0, jobid.1, jobid.2, etc. 




</br>

launch_database_cluster.py 
----------------------------
* Launches a distributed Orchestrator (database cluster) and then uses SmartRedis to communicate with it. 
* Used to show users how they can interact with the database. 
* Requires adding the interface to `launch_database_cluster.py`. 

```bash 
sbatch launch_database_cluster.sh
```

Sets up a database across 3 of the nodes. All have IPs + port 6780 assigned. Get a "reporting for duty" from all 3 threads. 

```bash 
Array put in database: [1 2 3 4]
Array retrieved from database: [1 2 3 4]
```


</br>

launch_multiple.py
-------------------

* Launch a database cluster across 3 nodes (same as `launch_database_cluster.py`) and a data producer which will put and get data from the Orchestrator using SmartRedis. 
* Requires adding the interface to `launch_multiple.py`. 

```bash 
sbatch launch_multiple.sh
```

* The clustered database needs 3 nodes ALONE, a 4th needs to be used for the application. Database needs to be isolated on it's own node for better performance. 


</br>


launch_mnist.py 
----------------

* Launches an orchestrator, a Loader and a Trainer process. 
* Loader: gets the MNIST dataset from the disk and puts it in the database 
* Trainer: gets MNIST from the database, trains a ResNet18 instance and puts the model on the DB 
* Loader: Uploads the test set on to the database and computes the accuracy 

Requires 3 nodes, using a single node database. 

Set up: 
```bash 
export PREFIX=/path/to/install/location
eval "$($PREFIX/miniconda3/bin/conda shell.bash hook)" 
conda activate a2-smartsim
python get_mnist.py 
```

Changes: 
* launch_mnist.sh: `export SR_SOCKET_TIMEOUT=20000`
* launch_mnist.py: `experiment.create_database`, add `interface=['hsn0', 'hsn1']`. 
* mnist_script.py: comment out `import torch`

Launch on 3 nodes: 
```bash 
sbatch launch_mnist.sh 
```
