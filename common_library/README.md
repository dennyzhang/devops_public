# Update cksum
cd .

library_sh="devops_common_library.sh"
tmp_sh="/tmp/test_$$.sh"

for f in *_helper.sh; do
    new_cksum="$(cksum "$f")"
    if ! grep "$new_cksum" $library_sh 1>/dev/null 2>&1; then
        echo "Update $library_sh for $f"
        sed "s/.* $f/$new_cksum/g" "$library_sh" > "$tmp_sh"
        mv "$tmp_sh" "$library_sh"
    fi
done

cksum *.sh > cksum.txt

# Get devops_common_library.sh cksum, then update existing scripts