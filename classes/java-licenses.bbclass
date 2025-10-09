# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: 2025 Joseph Mills <josephjamesmills@gmail.com>
do_populate_lic:prepend() {
    srcdir = d.getVar('S')

    checksum_map = {
        'Apache-2.0': [
             '3b83ef96387f14655fc854ddc3c6bd57'
         ],
         'BSD-3-Clause': [
             '71f739ef75581cae312e8c711bcdab16'
         ],
         'EPL-1.0': [
             'd0fc088e4e5216422c217d39853d8601'
         ],
    }

    # generate flat list of used license identifiers
    package_license_statement = d.getVar('LICENSE') or ''
    package_license_statement = package_license_statement.replace("&", " ")
    package_license_statement = package_license_statement.replace("(", " ")
    package_license_statement = package_license_statement.replace("|", " ")
    package_license_statement = package_license_statement.replace(")", " ")
    recipe_licenses = package_license_statement.split()
    recipe_licenses = list(map(str.strip, recipe_licenses))

    package_license_qa_whitelist = d.getVar('REUSE_LICENSECHECK_WHITELIST') or ''
    recipe_licenses_qa_whitelist = package_license_qa_whitelist.split()
    recipe_licenses_qa_whitelist = list(map(str.strip, recipe_licenses_qa_whitelist))
    recipe_licenses_qa_whitelist.append("CC0-1.0")

    if d.getVar('LIC_FILES_CHKSUM') and not d.getVar('LIC_FILES_CHKSUM') == '':
        print("Skip LIC_FILES_CHKSUM computation, value already set to:", d.getVar('LIC_FILES_CHKSUM'))
    else:
        checksum_entries = [" "]
        for license_id in recipe_licenses:
            license_file_path = os.path.join(d.getVar('LAYERDIR'), 'licenses/' + license_id )
            if os.path.exists(license_file_path):
                md5chksum = bb.utils.md5_file(license_file_path)
                if md5chksum in checksum_map[license_id]:
                    entry = "file://licenses/" + license_id + ".txt;md5=" + md5chksum
                    checksum_entries.append(entry)
                else:
                    bb.warn("QA Issue: %s [%s]" % (license_id + " not found in checksum table, md5sum=" + md5chksum, "reuse_license"))
                break
            else:
                bb.error("License not in licenses/ file, check license statement: ", license_id)

        separator = " "
        d.setVar('LIC_FILES_CHKSUM', separator.join(checksum_entries))
        print('Set LIC_FILES_CHKSUM from known SPDX files to:', d.getVar('LIC_FILES_CHKSUM'))

    # QA test for complete statement
    if d.getVar('JAVA_REUSE_LICENSECHECK_ENABLED') and d.getVar('JAVA_REUSE_LICENSECHECK_ENABLED') == '1':
        src_licenses = os.listdir(os.path.join(d.getVar(LAYERDIR), 'licenses/'))
        for license_file in src_licenses:
            license_name = license_file
            if license_name.endswith('.txt'):
                license_name = license_name[:-4]

            if license_name in checksum_map:
                if license_name in set(recipe_licenses):
                    continue
            if license_name in recipe_licenses_qa_whitelist:
                continue
            bb.warn("QA Issue: %s [%s]" % (license_name + " found in SRC but not in package license statement", "reuse_license"))
}
