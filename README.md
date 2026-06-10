# Bug-Bounty-Toolkit

## How To Use

1. Do you have wildcard domains?

Run the `setup.sh` script. This will populate the required files and folder structure. It will instruct you to populate three input files. Populate the files if applicable, then run the script again.

2. Do you not have wildcard domains?

Run the `setup.sh` script only once - then run the `recon_pipeline/recon.py` and `historical_analysis/historical.sh` scripts to avoid subdomain enumeration.


## Script Documentation

__Subdomain Enumeration__
```bash
python3 subdomain_enumeration/sub_eum.py \
    --wildcards wildcards.txt \ 
    --known known_subdomains.txt \
    --exclude out_of_scope.txt \
    --output output.txt
```

__Recon Pipeline__
```bash
python3 recon_pipeline/recon.py \
    --input subdomain_list.txt \
    --output output_dir/
```

__Historical Analysis__
```bash
./historical_analysis/historical.sh subdomain_list.txt output_dir/
```


## Tools Used

- amass
- subfinder
- assetfinder
- httpx
- naabu
- nmap
- gowitness
- katana
- waybackurls
- gau
- unfurl
- jq