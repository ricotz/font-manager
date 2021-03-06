/* ArchiveManager.vala
 *
 * Copyright (C) 2009 - 2016 Jerry Casiano
 *
 * This file is part of Font Manager.
 *
 * Font Manager is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Font Manager is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Font Manager.  If not, see <http://www.gnu.org/licenses/gpl-3.0.txt>.
 *
 * Author:
 *        Jerry Casiano <JerryCasiano@gmail.com>
*/

#if HAVE_FILE_ROLLER

/* Mimetypes that are likely to cause an error, unlikely to contain usable fonts.
 * i.e.
 * Windows .FON files are classified as "application/x-ms-dos-executable"
 * but file-roller is unlikely to extract one successfully.
 * */
const string [] ARCHIVE_IGNORE_LIST = {
    "application/x-ms-dos-executable"
};

[DBus (name = "org.gnome.ArchiveManager1")]
interface DBusService : Object {

    public signal void progress (double percent, string message);

    public abstract void add_to_archive (string archive, string [] files, bool use_progress_dialog) throws IOError;
    public abstract void compress (string [] files, string destination, bool use_progress_dialog) throws IOError;
    public abstract void extract (string archive, string destination, bool use_progress_dialog) throws IOError;
    public abstract void extract_here (string archive, bool use_progress_dialog) throws IOError;
    /* Valid actions -> "create", "create_single_file", "extract" */
    public abstract HashTable <string, string> [] get_supported_types (string action) throws IOError;

}

public class ArchiveManager : Object {

    public signal void progress (string? message, int processed, int total);

    DBusService? service = null;

    public void post_error_message (Error e) {
        critical("Archive Manager : %s", e.message);
    }

    void init () {
        try {
            service = Bus.get_proxy_sync(BusType.SESSION, "org.gnome.ArchiveManager1", "/org/gnome/ArchiveManager1");
            service.progress.connect((p, m) => { progress(m, (int) p, 100); });
            debug("Success contacting Archive Manager service.");
        } catch (IOError e) {
            warning("Failed to contact Archive Manager service.");
            warning("Features which depend on Archive Manager will not function correctly.");
            post_error_message(e);
        }
        return;
    }

    DBusService file_roller {
        get {
            init();
            return service;
        }
    }

    public bool add_to_archive (string archive, string [] uris, bool use_progress_dialog = true) {
        debug("Archive Manager - Add to archive : %s", archive);
        try {
            file_roller.add_to_archive(archive, uris, use_progress_dialog);
            return true;
        } catch (IOError e) {
            post_error_message(e);
        }
        return false;
    }

    public bool compress (string [] uris, string destination, bool use_progress_dialog = true) {
        debug("Archive Manager - Compress : %s", destination);
        try {
            file_roller.compress(uris, destination, use_progress_dialog);
            return true;
        } catch (IOError e) {
            post_error_message(e);
        }
        return false;
    }

    public bool extract (string archive, string destination, bool use_progress_dialog = true) {
        debug("Archive Manager - Extract %s to %s", archive, destination);
        try {
            file_roller.extract(archive, destination, use_progress_dialog);
            return true;
        } catch (IOError e) {
            post_error_message(e);
        }
        return false;
    }

    public bool extract_here (string archive, bool use_progress_dialog = true) {
        debug("Archive Manager - Extract here : %s", archive);
        try {
            file_roller.extract_here(archive, use_progress_dialog);
            return true;
        } catch (IOError e) {
            post_error_message(e);
        }
        return false;
    }

    public Gee.ArrayList <string> get_supported_types (string action = "extract") {
        debug("Archive Manager - Get supported types");
        var _supported_types = new Gee.ArrayList <string> ();
        try {
            HashTable <string, string> [] array = file_roller.get_supported_types(action);
            foreach (var hashtable in array) {
                if (hashtable.get("mime-type") in ARCHIVE_IGNORE_LIST)
                    continue;
                _supported_types.add(hashtable.get("mime-type"));
            }
        } catch (Error e) {
            post_error_message(e);
        }
        return _supported_types;
    }

}

#endif /* HAVE_FILE_ROLLER */
