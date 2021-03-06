package org.dwbn.plugins.playlist.service

import com.devbrackets.android.playlistcore.components.playlisthandler.PlaylistHandler
import com.devbrackets.android.playlistcore.service.BasePlaylistService
import org.dwbn.plugins.playlist.App
import org.dwbn.plugins.playlist.data.AudioTrack
import org.dwbn.plugins.playlist.manager.Options
import org.dwbn.plugins.playlist.manager.PlaylistManager
import org.dwbn.plugins.playlist.playlist.AudioApi
import org.dwbn.plugins.playlist.playlist.AudioPlaylistHandler
import org.dwbn.plugins.playlist.service.MediaImageProvider.OnImageUpdatedListener

/**
 * A simple service that extends [BasePlaylistService] in order to provide
 * the application specific information required.
 */
class MediaService : BasePlaylistService<AudioTrack, PlaylistManager>() {
    override fun onCreate() {
        super.onCreate()
        // Adds the audio player implementation, otherwise there's nothing to play media with
        val newAudio = AudioApi(applicationContext)
        //newAudio.addErrorListener(playlistManager)
        playlistManager.mediaPlayers.add(newAudio)
        //playlistManager.onMediaServiceInit(true)
    }

    override fun onDestroy() {
        super.onDestroy()

        // Releases and clears all the MediaPlayersMediaImageProvider
        for (player in playlistManager.mediaPlayers) {
            player.release()
        }
        playlistManager.mediaPlayers.clear()
    }

    override val playlistManager: PlaylistManager
        get() = (applicationContext as App).playlistManager

    override fun newPlaylistHandler(): PlaylistHandler<AudioTrack> {
        //val options = playlistManager.options
        val imageProvider = MediaImageProvider(applicationContext, object : OnImageUpdatedListener {
            override fun onImageUpdated() {
                playlistHandler.updateMediaControls()
            }
        }, Options(applicationContext))
       /* val listener: DefaultPlaylistHandler.Listener<AudioTrack> = object : DefaultPlaylistHandler.Listener<AudioTrack> {
            override fun onMediaPlayerChanged(oldPlayer: MediaPlayerApi<AudioTrack>?, newPlayer: MediaPlayerApi<AudioTrack>?) {
                playlistManager.onMediaPlayerChanged(newPlayer)
            }

            override fun onItemSkipped(item: AudioTrack) {
                // We don't need to do anything with this right now
                // The PluginManager receives notifications of the current item changes.
            }
        }*/
        return AudioPlaylistHandler.Builder(
                applicationContext,
                javaClass,
                playlistManager,
                imageProvider,
                null
        ).build()
    }
}